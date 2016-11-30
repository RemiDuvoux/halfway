class OffersController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    # NEWFANGLED CACHE APPROACH
    # TESTING
    airports = %w(PAR BER BRU MXP LON MAD BCN DUB HEL LCA RIX VNO)
    origin_a = "AMS"
    origin_b = "LIS"
    date_there = "2016-12-15"
    date_back = "2016-12-21"
    routes = Avion.generate_triple_routes(airports, origin_a, origin_b)

    @offers = []

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

    # sort by price
    @offers = @offers.sort_by { |offer| offer.total }
    # and remove duplicate cities
    @offers = @offers.uniq { |offer| offer.destination_city }
  end
end
