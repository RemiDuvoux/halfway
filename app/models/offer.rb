class Offer
  attr_reader :destination_city, :total, :roundtrips
  def initialize(args = {})
    @destination_city = args[:destination_city]
    @total = args[:total]
    @roundtrips = args[:roundtrips] # this is an array that holds two RoundTrip instances
  end
end
