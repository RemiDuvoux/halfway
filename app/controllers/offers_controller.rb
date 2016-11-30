require 'redis'

class OffersController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    # TESTING
    # airports = %w(PAR BER BRU)
    # origin_a = "AMS"
    # origin_b = "LIS"
    # date_there = "2016-12-15"
    # date_back = "2016-12-21"
    # routes = Avion.generate_routes(airports, origin_a, origin_b)
    #
    # routes[:from_b].each do |route|
    #   Avion.query_qpx_granular(route, date_there, date_back, "mock_results")
    # end

    # Granular comparison logic
    @offres = []

    search_info = {
      date_there: "2016-12-15",
      date_back: "2016-12-21",
      origin_a: "AMS",
      origin_b: "LIS"
    }

    json_a = File.open("mock_results/AMS_BER_2016-12-15_2016-12-21.json").read
    json_b = File.open("mock_results/LIS_BER_2016-12-15_2016-12-21.json").read
    comp = Avion::QPXComparatorGranular.new(json_a, json_b, search_info)
    @offres.concat(comp.compare)

    # json_a = File.open("mock_results/AMS_BRU_2016-12-15_2016-12-21.json").read
    # json_b = File.open("mock_results/LIS_BRU_2016-12-15_2016-12-21.json").read
    # comp = Avion::QPXComparatorGranular.new(json_a, json_b)
    # @offres.concat(comp.compare)

    @offres = @offres.sort_by { |offer| offer.total }
    @offres = @offres.uniq { |offer| offer.destination_city }

    raise

    jsons_from_a = eval(File.open("mock_from_lis.txt", "rb").read)
    jsons_from_b =  eval(File.open("mock_from_vno.txt", "rb").read)
    comparator = Avion::QPXComparator.new(jsons_from_a, jsons_from_b)
    @offers = comparator.combine_prices.sort_by { |offer| offer.total }
    @offers = @offers.uniq { |offer| offer.destination_city } # filter out duplicate cities
  end
end
