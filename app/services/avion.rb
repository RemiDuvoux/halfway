module Avion
  # MODULE METHODS

  def self.generate_triple_routes(airports, origin_a, origin_b)
    triples = airports.map do |airport|
      if airport != origin_a && airport!= origin_b
        [origin_a, origin_b, airport]
      end
    end
    triples.compact
  end

  # TODO: DRYer (offers controller, private generate_cache_name for SmartQPXAgent)
  def self.compare_routes_against_cache(routes, date_there, date_back)
    routes.reject do |route|
      alphabetical = [route.first, route[1]].sort
      $redis.exists("#{alphabetical.first}_#{alphabetical.last}_#{route.last}_#{date_there}_#{date_back}")
    end
  end
end
