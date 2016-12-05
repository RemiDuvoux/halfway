module OffersHelper
  def departure_css_class_name(filter)
    return "active" if filter == @filters[:departure_time_there]
  end

  def arrival_css_class_name(filter)
    return "active" if filter == @filters[:arrival_time_back]
  end
end
