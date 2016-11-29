class ResultsController < ApplicationController
  skip_before_action :authenticate_user!

  def autocomplete_airport_name
    term = params[:term]
    cities = City.where('name LIKE ?', "%#{term}%").order(:name)
    render :json => cities.map { |city| {:id => city.id, :label => city.name, :value => city.iata_code } }
  end

  def index
    @results = Result.all
  end
end
