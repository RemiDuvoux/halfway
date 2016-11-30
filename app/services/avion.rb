require 'rest-client' # Make sure you have this gem!
require 'json'

module Avion
  # Wraps an individual QPX response
  class QPXResponse
    attr_reader :trips
    def initialize(json) # in JSON
      @data = JSON.parse(json)
      # safeguard for when there are no flights (e.g. Bad Response)
      if !@data['trips']['tripOption'].nil?
        trips = create_trips(@data['trips']['tripOption'])
      else
        trips = [QPXTripOption.new({})]
      end
      @trips = trips
      # should we nilify data after initialization?
    end

    private

    def create_trips(trips)
      trips.map do |trip|
        QPXTripOption.new(trip)
      end
    end
  end

  # Wraps an individual QPX trip option inside each response
  class QPXTripOption
    attr_reader :price, :destination_city, :destination_airport,
                :origin_airport, :departure_time_there, :arrival_time_there,
                :departure_time_back, :arrival_time_back, :currency, :carrier
    def initialize(option)
      return if option == {} # Safeguard if we had a bad response in JSON. Extraction methods won't be called on nil
      @currency = nil # will be assigned by the call to extract_total_price
      @price = extract_total_price(option)
      @destination_city = extract_destination_city(option)
      @destination_airport = extract_destination_airport(option)
      @origin_airport = extract_origin_airport(option)
      @departure_time_there = extract_departure_time(option, 0)
      @arrival_time_there = extract_arrival_time(option, 0)
      @departure_time_back = extract_departure_time(option, 1)
      @arrival_time_back = extract_arrival_time(option, 1)
      @carrier = extract_carrier(option)
    end

    private

    def extract_carrier(trip)
      trip['slice'].first['segment'].first['flight']['carrier']
    end

    def extract_departure_time(trip, slice)
      Time.parse trip['slice'][slice]['segment'].first['leg'].first['departureTime']
    end

    def extract_arrival_time(trip, slice)
      Time.parse trip['slice'][slice]['segment'].first['leg'].first['arrivalTime']
    end

    # TODO: Account for pound instead of koruna
    def extract_total_price(trip)
      @currency = trip['saleTotal'].match(/\w{3}/).to_s
      # Mock currency convertion for czech koruna (* 0.037 to get EUR)
      # TODO: get rid of in actual project, will only work in eurozone for the demo
      if @currency == "CZK"
        (trip['saleTotal'].match(/\d+\.*\d+/)[0].to_f * 0.037).round(2)
      else
        trip['saleTotal'].match(/\d+\.*\d+/)[0].to_f
      end
    end

    def extract_destination_city(trip)
      # This is how we get to the city cody
      trip['pricing'].first['fare'].first['destination']
    end

    def extract_origin_airport(trip)
      trip['pricing'].first['fare'].first['origin']
    end

    def extract_destination_airport(trip)
      # This is how we get to destination airport code
      trip['slice'].first['segment'].first['leg'].first['destination']
    end
  end

  # Has a method #make_request that sends a request to QPX and gets a response
  # in original JSON
  class QPXRequester
    # date should be a string in "YYYY-MM-DD" format
    def initialize(args = {})
      @origin = args[:origin] # airport code
      @destination = args[:destination]
      @date_there = args[:date_there]
      @date_back = args[:date_back]
      @trip_options = args[:trip_options]
      @api_key = args[:api_key]
    end

    def make_request
      url = "https://www.googleapis.com/qpxExpress/v1/trips/search?key=" + @api_key
      request = compose_request
      response = RestClient.post url, request, {content_type: :json, accept: :json}
      response.body
    end

    private

    def compose_request
      # HERE IS A QPX ACCEPTED REQUEST FORM
      # ONLY CHANGE IT TO MAKE MORE VALUES DYNAMIC
      # WITHOUT BREAKING THE STRUCTURE!
      request_hash = {
        "request"=>
        {"slice"=>[
          {"origin"=>@origin, "destination"=>@destination, "date"=>@date_there, "maxStops"=>0},
          {"origin"=>@destination, "destination"=>@origin, "date"=>@date_back, "maxStops"=>0}
        ],
        "passengers"=>
        {"adultCount"=>1,
          "infantInLapCount"=>0,
          "infantInSeatCount"=>0,
          "childCount"=>0,
          "seniorCount"=>0},
          "solutions"=>@trip_options,
          "refundable"=>false}
        }
      return JSON.generate(request_hash)
    end
  end

  # Query QPX two requests at a time, only make request if corresponding Offer
  # is not found in Redis cache. Our hope to run requests in parallel
  # TODO: remove debugging puts
  class SmartQPXAgent
    def initialize(args = {})
      @origin_a = args[:origin_a]
      @origin_b = args[:origin_b]
      @destination_city = args[:destination_city]
      @date_there = args[:date_there]
      @date_back = args[:date_back]
      @cache_key_name = generate_cache_key_name
      # DEBUG ONLY
      puts @cache_key_name
    end

    # TODO: Handle case when no offers found (see Avion command line tester)
    def obtain_offers
      # Get deserialized Offer object from cache if found
      if check_cache
        puts "Found key #{@cache_key_name} in cache"
        return Marshal.load($redis.get(@cache_key_name))
      end

      # If not – run two requests one after another and try to combine them
      json_a = Avion::QPXRequester.new(
      origin: @origin_a, destination: @destination_city, date_there: @date_there, date_back: @date_back, trip_options: 5, api_key: ENV["QPX_KEY"]).make_request
      # DEBUG ONLY
      puts "#{@origin_a} - #{@destination_city} request made to QPX"

      json_b = Avion::QPXRequester.new(
      origin: @origin_b, destination: @destination_city, date_there: @date_there, date_back: @date_back, trip_options: 5, api_key: ENV["QPX_KEY"]).make_request
      # DEBUG ONLY
      puts "#{@origin_b} - #{@destination_city} request made to QPX"

      # Form the params hash to pass to Comparator
      comp_info = {
        date_there: @date_there,
        date_back: @date_back,
        origin_a: @origin_a,
        origin_b: @origin_b
      }

      comparator = Avion::QPXComparatorGranular.new(json_a, json_b, comp_info)
      output = comparator.compare
      $redis.set(@cache_key_name, Marshal.dump(output))
      return output
    end

    private

    def check_cache
      $redis.get(@cache_key_name) != nil
    end

    def generate_cache_key_name
      "#{@origin_a}_#{@origin_b}_#{@destination_city}_#{@date_there}_#{@date_back}"
    end
  end

  class Comparator
    def initialize(args = {})
      @origin_a = args[:origin_a]
      @origin_b = args[:origin_b]
      @date_there = Date.parse(args[:date_there]) unless args[:date_there].nil?
      @date_back = Date.parse(args[:date_back]) unless args[:date_back].nil?
    end
  end

  # We use it in SmartQPXAgent
  class QPXComparatorGranular < Comparator
    def initialize(json_from_a, json_from_b, args = {})
      @result_a = QPXResponse.new(json_from_a)
      @result_b = QPXResponse.new(json_from_b)
      super(args)
    end

    # this is where the magic happens
    def compare
      output = []
      @result_a.trips.each do |trip_1|
        @result_b.trips.each do |trip_2|
          next if trip_1.price == nil || trip_2.price == nil # safeguard if the trip is an empty object
          if trip_1.destination_city == trip_2.destination_city
            output << Offer.new(
            origin_a: @origin_a,
            origin_b: @origin_b,
            destination_city: trip_1.destination_city,
            date_there: @date_there,
            date_back: @date_back,
            total: trip_1.price + trip_2.price,
            # we agnosticize QPXTripOption here
            roundtrips: [
              RoundTrip.new(qpx_trip_option: trip_1),
              RoundTrip.new(qpx_trip_option: trip_2)
            ]
            )
          end
        end
      end
      output
    end
  end

  # Our main comparison logic goes here. Takes two arrays of JSON QPX responses
  # one for each origin
  class QPXComparator < Comparator
    def initialize(jsons_one, jsons_two, args = {})
      @results_one = objectify(jsons_one)
      @results_two = objectify(jsons_two)
      @all_trips_one = list_all_trips(@results_one)
      @all_trips_two = list_all_trips(@results_two)
      super(args)
    end

    # Our main secret sauce for now
    def combine_prices
      output = []
      @all_trips_one.each do |trip_1|
        @all_trips_two.each do |trip_2|
          next if trip_1.price == nil || trip_2.price == nil # safeguard if the trip is an empty object
          if trip_1.destination_city == trip_2.destination_city
            output << Offer.new(
            destination_city: trip_1.destination_city,
            total: trip_1.price + trip_2.price,
            # we agnosticize QPXTripOption here
            roundtrips: [
              RoundTrip.new(qpx_trip_option: trip_1),
              RoundTrip.new(qpx_trip_option: trip_2)
            ]
            )
          end
        end
      end
      output
    end

    private

    def objectify(jsons)
      jsons.map do |json|
        QPXResponse.new(json)
      end
    end

    def list_all_trips(results)
      results.map { |result| result.trips }.flatten
    end
  end

  # MODULE METHODS

  # A helper to build arrays of possible flights for each of two origins
  # use 3-letter airport codes as arguments
  def self.generate_routes(airports, origin1, origin2)
    possible_from_origin1 = airports.map do |airport|
      if airport != origin1 && airport!= origin2
        [origin1, airport]
      end
    end

    possible_from_origin2 = airports.map do |airport|
      if airport != origin1 && airport!= origin2
        [origin2, airport]
      end
    end

    return {
      from_a: possible_from_origin1.compact,
      from_b: possible_from_origin2.compact
    }
  end

  def self.generate_triple_routes(airports, origin_a, origin_b)
    triples = airports.map do |airport|
      if airport != origin_a && airport!= origin_b
        [origin_a, origin_b, airport]
      end
    end
    triples.compact
  end

  def self.print_result(result, results)
    roundtrip_a = result.roundtrips.first
    roundtrip_b = result.roundtrips.last

    nth = results.index(result)

    puts "According to our little fairies, the number #{nth + 1} cheapest city to get from #{roundtrip_a.origin_airport} and #{roundtrip_b.origin_airport} is #{result.destination_city}"
    puts "Ann flies with #{roundtrip_a.carrier}:"
    puts "Flight 1:"
    puts "From #{roundtrip_a.origin_airport} to #{roundtrip_a.destination_airport} departing on #{roundtrip_a.departure_time_there}, arriving on #{roundtrip_a.arrival_time_there}"
    puts "Flight 2:"
    puts "From #{roundtrip_a.destination_airport} to #{roundtrip_a.origin_airport} departing on #{roundtrip_a.departure_time_back}, arriving on #{roundtrip_a.arrival_time_back}"
    puts "Cost for Ann: #{roundtrip_a.price}#{roundtrip_a.currency}"
    puts ""
    puts "Bob flies with #{roundtrip_b.carrier}:"
    puts "Flight 1:"
    puts "From #{roundtrip_b.origin_airport} to #{roundtrip_b.destination_airport} departing on #{roundtrip_b.departure_time_there}, arriving on #{roundtrip_b.arrival_time_there}"
    puts "Flight 2:"
    puts "From #{roundtrip_b.destination_airport} to #{roundtrip_b.origin_airport} departing on #{roundtrip_b.departure_time_back}, arriving on #{roundtrip_b.arrival_time_back}"
    puts "Cost for Bob: #{roundtrip_b.price}#{roundtrip_b.currency}"

    puts "Total cost for both:"
    puts "#{result.total.round(2)}"

    puts "========"
  end

  def self.html_result(result, results)
    roundtrip_a = result.roundtrips.first
    roundtrip_b = result.roundtrips.last

    nth = results.index(result)

    html = "<p><strong>Number #{nth + 1}</strong> cheapest city to get from #{roundtrip_a.origin_airport} and #{roundtrip_b.origin_airport} is <strong>#{result.destination_city}</strong>" + "<br>"
    html += "<br>"
    html += "Ann flies with #{roundtrip_a.carrier}:" + "<br>"
    html += "Flight there:" + "<br>"
    html += "From #{roundtrip_a.origin_airport} to #{roundtrip_a.destination_airport} departing on #{roundtrip_a.departure_time_there}, arriving on #{roundtrip_a.arrival_time_there}" + "<br>"
    html += "Flight back:" + "<br>"
    html += "From #{roundtrip_a.destination_airport} to #{roundtrip_a.origin_airport} departing on #{roundtrip_a.departure_time_back}, arriving on #{roundtrip_a.arrival_time_back}" + "<br>"
    html += "Cost for Ann: #{roundtrip_a.price}#{roundtrip_a.currency}" + "<br>"
    html += "<br>"
    html += "Bob flies with #{roundtrip_b.carrier}:" + "<br>"
    html += "Flight there:" + "<br>"
    html += "From #{roundtrip_b.origin_airport} to #{roundtrip_b.destination_airport} departing on #{roundtrip_b.departure_time_there}, arriving on #{roundtrip_b.arrival_time_there}" + "<br>"
    html += "Flight back:" + "<br>"
    html += "From #{roundtrip_b.destination_airport} to #{roundtrip_b.origin_airport} departing on #{roundtrip_b.departure_time_back}, arriving on #{roundtrip_b.arrival_time_back}" + "<br>"
    html += "Cost for Bob: #{roundtrip_b.price}#{roundtrip_b.currency}" + "<br>"
    html += "<br>"
    html += "<strong>Total cost for both: #{result.total.round(2)}</strong>"

    return html
  end


  # Query QPX one request at a time for testing
  def self.query_qpx_solo(route, date_there, date_back, cache_dir)
   json = Avion::QPXRequester.new(origin: route.first, destination: route.last, date_there: date_there, date_back: date_back, trip_options: 5, api_key: ENV["QPX_KEY"]).make_request
   path = File.join(cache_dir, Avion.generate_json_filename(route, date_there, date_back)) + ".json"
   File.open(path, 'w') { |file| file.write(json) }
   return json
  end

  # Query QPX in bulk for testing
  def self.query_qpx(routes, date_there, date_back, cache)
    jsons = []
    routes.each do |route|
      jsons << Avion::QPXRequester.new(origin: route.first, destination: route.last, date_there: date_there, date_back: date_back, trip_options: 5, api_key: ENV["QPX_KEY"]).make_request
    end
    # Write all jsons to file for caching during testing
    File.open(cache, 'w') { |file| file.write(jsons) }
    return jsons
  end

  def self.generate_json_filename(route, date_there, date_back)
    "#{route.first}_#{route.last}_#{date_there}_#{date_back}"
  end
end
