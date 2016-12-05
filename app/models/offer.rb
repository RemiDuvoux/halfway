class Offer
  attr_reader :destination_city, :total, :roundtrips, :origin_a, :origin_b,
              :date_there, :date_back, :stamp
  def initialize(args = {})
    @destination_city = args[:destination_city]
    @total = args[:total]
    @roundtrips = args[:roundtrips] # this is an array that holds two RoundTrip instances
    @origin_a = args[:origin_a]
    @origin_b = args[:origin_b]
    @date_there = args[:date_there]
    @date_back = args[:date_back]
    @stamp = generate_stamp
  end

  private

  def generate_stamp
    alphabetical = [@origin_a, @origin_b].sort
    "#{alphabetical.first}_#{alphabetical.last}_#{@destination_city}_#{@date_there}_#{@date_back}"
  end
end
