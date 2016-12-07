module Avion
  # Wraps an individual QPX trip option inside each response
  class QPXTripOption
    attr_reader :price, :destination_city, :destination_airport,
                :origin_airport, :departure_time_there, :arrival_time_there,
                :departure_time_back, :arrival_time_back, :currency, :carrier, :trip_id,
                :flight_number_there, :flight_number_back
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
      @flight_number_there = @carrier + extract_flight_number(option, 0)
      @flight_number_back = @carrier + extract_flight_number(option, 1)
      @trip_id = extract_trip_id(option)
    end

    private

    def extract_carrier(trip)
      trip['slice'].first['segment'].first['flight']['carrier']
    end

    def extract_flight_number(trip, slice)
      trip['slice'][slice]['segment'].first['flight']['number']
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
      # TODO: Find a way to pull live currency data
      if @currency == "GBP"
        (trip['saleTotal'].match(/\d+\.*\d+/)[0].to_f * 1.19).round(2)
      else
        trip['saleTotal'].match(/\d+\.*\d+/)[0].to_f
      end
    end

    def extract_trip_id(trip)
      trip['id']
    end

    def extract_destination_city(trip)
      # This is how we get to the city cody
      trip['pricing'].first['fare'].first['destination']
    end

    def extract_origin_airport(trip)
      trip['slice'].first['segment'].first['leg'].first['origin']
    end

    def extract_destination_airport(trip)
      # This is how we get to destination airport code
      trip['slice'].first['segment'].first['leg'].first['destination']
    end
  end
end
