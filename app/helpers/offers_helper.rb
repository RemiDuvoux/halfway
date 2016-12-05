module OffersHelper
  def departure_css_class_name(filter)
    return "active" if filter == @filters[:departure_time_there]
  end

  def arrival_css_class_name(filter)
    return "active" if filter == @filters[:arrival_time_back]
  end

  def date_a(offers)
    offers.first.date_there.strftime("%b %d") if offers.present?
  end

  def date_b(offers)
    @offers.first.date_back.strftime("%b %d") if offers.present?
  end
end
