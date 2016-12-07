module Avion
  # Query QPX two requests at a time, only make request if corresponding Offer
  # is not found in Redis cache.
  # TODO: remove debugging puts
  class SmartQPXAgent
    def initialize(args = {})
      @origin_a = args[:origin_a]
      @origin_b = args[:origin_b]
      @destination_city = args[:destination_city]
      @date_there = args[:date_there]
      @date_back = args[:date_back]
      @cache_key_name = generate_cache_key_name
      # while in development
      puts @cache_key_name
    end

    def obtain_offers
      # Get deserialized Offer object from cache if found
      cached = $redis.get(@cache_key_name)
      if cached
        puts "Found key #{@cache_key_name} in cache"
        return Marshal.load(cached)
      end

      # If not – run two requests one after another and try to combine them
      start = Time.now # debugging
      json_a = Avion::QPXRequester.new(
      origin: @origin_a, destination: @destination_city, date_there: @date_there, date_back: @date_back, trip_options: 5, api_key: ENV["QPX_KEY"]).make_request
      # DEBUG ONLY
      puts "#{@origin_a} - #{@destination_city} request made to QPX"
      finish = Time.now # debugging
      took_seconds = (finish - start).round(2)

      # Pub-sub part
      # Notify first request is made
      Pusher.trigger('qpx_updates', 'request_made', {
        origin: @origin_a,
        destination: @destination_city,
        took_seconds: took_seconds
      })

      start = Time.now # debugging
      json_b = Avion::QPXRequester.new(
      origin: @origin_b, destination: @destination_city, date_there: @date_there, date_back: @date_back, trip_options: 5, api_key: ENV["QPX_KEY"]).make_request
      # DEBUG ONLY
      puts "#{@origin_b} - #{@destination_city} request made to QPX"
      finish = Time.now # debugging
      took_seconds = (finish - start).round(2)

      # Notify second request is made
      Pusher.trigger('qpx_updates', 'request_made', {
        origin: @origin_b,
        destination: @destination_city,
        took_seconds: took_seconds
      })

      comp_info = {
        date_there: @date_there,
        date_back: @date_back,
        origin_a: @origin_a,
        origin_b: @origin_b
      }

      comparator = Avion::QPXComparatorGranular.new(json_a, json_b, comp_info)
      output = comparator.compare
      $redis.set(@cache_key_name, Marshal.dump(output))

      # Notify we are ready to return request data
      Pusher.trigger('qpx_updates', 'requests_completed', {
        increment: 1,
        roundtrips_analyzed: output.length
      })

      # return an array of matched offers
      return output
    end

    private

    # TODO: DRY with offers controller and check_against_cache
    def generate_cache_key_name
      alphabetical = [@origin_a, @origin_b].sort
      "#{alphabetical.first}_#{alphabetical.last}_#{@destination_city}_#{@date_there}_#{@date_back}"
    end
  end
end
