class ResultsController < ApplicationController
  autocomplete :airport, :name

  def index
    @results = Result.all
  end
end
