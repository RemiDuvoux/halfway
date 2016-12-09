class City < ApplicationRecord

  CITY = {
    "Paris" => "PAR",
    "London" => "LON",
    "Roma" => "ROM",
    "Madrid" => "MAD",
    "Berlin" => "BER",
    "Athens" => "ATH",
    "Milano" => "MXP",
    "Venice" => "VCE",
    "Amsterdam" => "AMS",
    "Lisbon" => "LIS",
    "Dublin" => "DUB",
    "Helsinki" => "HEL",
    "Barcelona" => "BCN",
    "Cyprus" => "LCA",
    "Florence" => "FLR",
    "Malta" => "MLA",
    "Vienna" => "VIE",
    "Riga" => "RIX",
    "Vilnius" => "VNO",
    "Brussels" => "BRU"
  }

  has_many :airports
  validates :name, presence: true

  has_attachment :background_photo
  has_attachment :card_photo
end
