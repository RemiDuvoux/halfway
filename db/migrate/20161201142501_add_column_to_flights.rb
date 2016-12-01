class AddColumnToFlights < ActiveRecord::Migration[5.0]
  def change
    add_column :flights, :departure_airport_iata_code, :string
    add_column :flights, :arrival_airport_iata_code, :string
  end
end
