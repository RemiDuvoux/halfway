class Offer
  attr_reader :destination_city, :total, :trips
  def initialize(args = {})
    @destination_city = args[:destination_city]
    @total = args[:total]
    @trips = args[:trips] # this is an array that holds two QPXTripOption instances
  end
end
