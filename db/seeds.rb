# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require 'csv'
csv_options = { col_sep: ',', headers: :first_row }


filepath ||= "#{Rails.root}/db/seed_cities.csv"
CSV.foreach(filepath, csv_options) do |row|
  new_city = City.create!(name: row[0], iata_code: row[1])
  new_city.save!
  new_city.card_photo_url = row[2]
  new_city.background_photo_url = row[3]
  new_city.save!
end

AIRPORTS = {
    "Paris" => "PAR",
    "London" => "LON",
    "Roma" => "ROM",
    "Madrid" => "MAD",
    "Berlin" => "BER",
    "Brussels" => "BRU",
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
  }

City.all.each do |city|
  Airport.create(city_id: city.id, iata_code: AIRPORTS[city.name])
end
