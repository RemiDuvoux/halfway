class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @airport = Airport.new
    @result = Result.new
  end

  def search
  end
end
