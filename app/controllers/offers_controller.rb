class OffersController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @offers = []

    search_info = {
      date_there: "2016-12-15",
      date_back: "2016-12-21",
      origin_a: "AMS",
      origin_b: "LIS"
    }

    json_a = File.open("mock_results/AMS_BER_2016-12-15_2016-12-21.json").read
    json_b = File.open("mock_results/LIS_BER_2016-12-15_2016-12-21.json").read
    comp = Avion::QPXComparatorGranular.new(json_a, json_b, search_info)
    @offers.concat(comp.compare)

    json_a = File.open("mock_results/AMS_BRU_2016-12-15_2016-12-21.json").read
    json_b = File.open("mock_results/LIS_BRU_2016-12-15_2016-12-21.json").read
    comp = Avion::QPXComparatorGranular.new(json_a, json_b, search_info)
    @offers.concat(comp.compare)

    @offers = @offers.sort_by { |offer| offer.total }
    @offers = @offers.uniq { |offer| offer.destination_city }

  end
end
