class OffersController < ApplicationController
  skip_before_action :authenticate_user!

  # Airport list: %w(PAR LON ROM MAD BER BRU ATH MXP VCE AMS LIS DUB HEL BCN LCA FLR MIL VIE RIX VNO)

  def wait
    #Waiting logic implemented directly in the view with JS
  end

  def show
    # safeguard agains random urls starting with /offers
    unless params[:stamp] =~ /\w{3}_\w{3}_\w{3}_\d{4}-\d{2}-\d{2}_\d{4}-\d{2}-\d{2}/ 
      redirect_to root_path
      return
    end

    from_stamp = params[:stamp].split('_')
    info = {
      origin_a: from_stamp.first,
      origin_b: from_stamp[1],
      destination_city: from_stamp[2],
      date_there: from_stamp[3],
      date_back: from_stamp.last
    }
    # All offers for one route sorted by price
    @offers = Avion::SmartQPXAgent.new(info).obtain_offers.sort_by { |offer| offer.total }
    # use query string to set the nth cheapest offer (zero-based), loop over to 0 if exceed array length
    idx = params[:cheapest].to_i < @offers.length ? params[:cheapest].to_i : 0
    @offer = @offers[idx]
  end

  def index
    # do not cache the page to avoid caching waiting animation
    response.headers['Cache-Control'] = "no-cache, max-age=0, must-revalidate, no-store"
    # if there are no query params in URL or they don't make sense - send user to home page
    if URI(request.original_url).query.blank? || params_fail?
      redirect_to root_path
      return
    end

    airports =  %w(PAR BER)

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
      # render wait view without any routing
      render action: :wait
      # Send requests and build the cache in the background
      QueryRoutesJob.perform_later(uncached_routes, date_there, date_back)
    end
  end

  private

  def params_fail?
    params[:origin_a].blank? || params[:origin_b].blank? || params[:date_there].blank? || params[:date_back].blank?
  end

end
