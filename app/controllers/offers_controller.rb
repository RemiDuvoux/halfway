class OffersController < ApplicationController
  skip_before_action :authenticate_user!

  # Airport list: %w(PAR LON ROM MAD BER BRU ATH MXP VCE AMS LIS DUB HEL BCN LCA FLR MIL VIE RIX VNO)

  def wait #Here we handle user waiting, but it's mostly done in the view with JS

    # this page should not ever be cached by the browser
    response.headers['Cache-Control'] = "no-cache, max-age=0, must-revalidate, no-store"
    # Prevent user from accessing this page directly by typing URL or by hitting back from /offers
    referer = session[:referer]
    session[:referer] = nil
    redirect_to root_path if request.referer.nil? || referer =~ /offers/
  end

  def index
    # if there are no query params in URL or they don't make sense - send user to home page
    if URI(request.original_url).query.blank? || params_fail?
      redirect_to root_path
      return
    end

    airports =  %w(PAR LON ROM MAD BER BRU ATH MXP VCE AMS LIS DUB HEL BCN LCA FLR MIL VIE RIX VNO)

    origin_a = params[:origin_a].upcase
    origin_b = params[:origin_b].upcase
    date_there = params[:date_there]
    date_back = params[:date_back]

    routes = Avion.generate_triple_routes(airports, origin_a, origin_b)
    # Test all routes against cache
    uncached_routes = Avion.compare_routes_against_cache(routes, date_there, date_back)

    # Do we have something that is not cached?
    if uncached_routes.empty?
      session[:referer] = request.original_url

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
      session[:url_for_wait] = request.original_url
      # send user to waiting page to watch animations
      redirect_to wait_path
      # Build the cache in the background
      QueryRoutesJob.perform_later(uncached_routes, date_there, date_back)
    end
  end

  private

  def params_fail?
    params[:origin_a].blank? || params[:origin_b].blank? || params[:date_there].blank? || params[:date_back].blank?
  end

end
