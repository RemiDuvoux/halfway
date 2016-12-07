module Avion
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
    # TODO: refactor with Rubocop!
    def compare
      # Creates an array of matched offers
      output = []
      @result_a.trips.each do |trip_1|
        @result_b.trips.each do |trip_2|
          next if trip_1.price == nil || trip_2.price == nil # safeguard if the trip is an empty object
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
      output
    end
  end
end
