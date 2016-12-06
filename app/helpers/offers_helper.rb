module OffersHelper
  def departure_css_class_name(filter)
    return "active" if filter == @filters[:departure_time_there]
  end

  def arrival_css_class_name(filter)
    return "active" if filter == @filters[:arrival_time_back]
  end

  def price_difference_styling(price1, price2)
    if price2 > price1
      return "#408000"
    elsif price1 > price2
      return "red"
    else
      return "black"
    end
  end

  def price_difference_text(price1, price2)
    if price2 > price1
      "Cheaper by €#{(price2 - price1).round}"
    elsif price1 > price2
      "More expensive by €#{(price2 - price1).round}"
    else
      "The price is the same!"
    end
  end
end
