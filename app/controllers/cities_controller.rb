class CitiesController < ApplicationController
  skip_before_action :authenticate_user!, only: :index
  def index
    @cities = City.all
  end
end
