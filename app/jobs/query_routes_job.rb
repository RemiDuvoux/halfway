class QueryRoutesJob < ApplicationJob
  queue_as :default

  def perform(routes, date_there, date_back)
    # With a list of 20 airports it will run 18 times
    # and make 36 QPX requests in total
    routes.each do |route|
      info = {
        origin_a: route.first,
        origin_b: route[1],
        destination_city: route.last,
        date_there: date_there,
        date_back: date_back
      }
      Avion::SmartQPXAgent.new(info).obtain_offers
    end
  end
end
