class OffersController < ApplicationController
  skip_before_action :authenticate_user!

  # Airport list: %w(PAR LON ROM MAD BER BRU ATH MXP VCE AMS LIS DUB HEL BCN LCA FLR MIL VIE RIX VNO)

  def wait
    #Here we handle user waiting
  end

  def index
    airports = %w(PAR LON ROM MAD)

    # We need to put default values if the user somehow gets here
    # not from the home page
    origin_a = params[:origin_a] || "AMS"
    origin_b = params[:origin_b] || "LIS"
    date_there = params[:date_there] || "2017-02-07"
    date_back = params[:date_back] || "2017-02-17"

    routes = Avion.generate_triple_routes(airports, origin_a, origin_b)

    # Test all routes against cache
    uncached_routes = Avion.compare_routes_against_cache(routes, date_there, date_back)
    # Do we have something that is not cached?
    if uncached_routes.empty?
      @offers = []
      # This won't do any API requests at all as we work only with cache
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
      # sort by total price
      @offers = @offers.sort_by { |offer| offer.total }
      # and remove duplicate cities
      @offers = @offers.uniq { |offer| offer.destination_city }
    else
      # we need this to be able to redirect user
      # to the page with same params in the url from the js in wait.html.erb
      session[:original_url] = request.original_url
      # send user to waiting page to watch animations
      redirect_to wait_path
      # Build the cache in the background
      QueryRoutesJob.perform_later(uncached_routes, date_there, date_back)
    end
  end

end
