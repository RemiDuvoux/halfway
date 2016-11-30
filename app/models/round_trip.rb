# An API agnostic version of QPXTripOption we use to refer inside of Offer
# A converter class. Use more initialization options with different APIs later
class RoundTrip
  attr_reader :price, :destination_city, :destination_airport,
              :origin_airport, :departure_time_there, :arrival_time_there,
              :departure_time_back, :arrival_time_back, :currency, :carrier
  def initialize(args={})
    unless args[:qpx_trip_option].nil?
      qpx = args[:qpx_trip_option]
      @currency = qpx.currency
      @price = qpx.price
      @destination_city = qpx.destination_city
      @destination_airport = qpx.destination_airport
      @origin_airport = qpx.origin_airport
      @departure_time_there = qpx.departure_time_there
      @arrival_time_there = qpx.arrival_time_there
      @departure_time_back = qpx.departure_time_back
      @arrival_time_back = qpx.arrival_time_back
      @carrier = qpx.carrier
    end
  end
end
