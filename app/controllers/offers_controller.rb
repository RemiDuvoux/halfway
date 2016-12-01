class OffersController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    # NEWFANGLED CACHE APPROACH
    # TESTING
    airports = %w(PAR LON ROM MAD BER BRU ATH MXP VCE AMS LIS DUB HEL BCN LCA FLR MIL VIE RIX VNO)
    origin_a = "AMS"
    origin_b = "LIS"
    date_there = "2017-02-03"
    date_back = "2017-02-06"
    routes = Avion.generate_triple_routes(airports, origin_a, origin_b)

    @offers = []

    start = Time.now

    # TODO: METHOD TO CHECK IF ALL CROSS-CHECK KEYS ARE IN REDIS

    # PUT THIS IN A JOB?

    # With a list of 20 airports it will run 18 times
    # and make 36 QPX requests in total
    routes.each do |route|
      info = {
        origin_a: route.first,
        origin_b: route[1],
        destination_city: route.last,
        date_there: date_there,
        date_back: date_back
      }
      @offers.concat(Avion::SmartQPXAgent.new(info).obtain_offers)
    end

    finish = Time.now

    puts "Requests took #{(finish - start).round(2)} seconds "

    # sort by total price
    @offers = @offers.sort_by { |offer| offer.total }
    # and remove duplicate cities
    @offers = @offers.uniq { |offer| offer.destination_city }
  end
end
