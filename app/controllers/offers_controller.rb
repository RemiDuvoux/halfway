require 'redis'

class OffersController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    jsons_from_a = eval(File.open("mock_from_lis.txt", "rb").read)
    jsons_from_b =  eval(File.open("mock_from_vno.txt", "rb").read)
    comparator = Avion::QPXComparator.new(jsons_from_a, jsons_from_b)
    @offers = comparator.combine_prices.sort_by { |offer| offer.total }
    @offers = @offers.uniq { |offer| offer.destination_city } # filter out duplicate cities
  end
end
