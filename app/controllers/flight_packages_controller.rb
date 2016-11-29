class FlightPackagesController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    jsons_from_a = eval(File.open("mock_from_lis.txt", "rb").read)
    jsons_from_b =  eval(File.open("mock_from_vno.txt", "rb").read)
    comparator = Avion::Comparator.new(jsons_from_a, jsons_from_b)
    @packages = comparator.combine_prices.sort_by { |info| info.total }
  end
end
