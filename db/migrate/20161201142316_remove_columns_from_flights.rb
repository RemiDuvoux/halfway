class RemoveColumnsFromFlights < ActiveRecord::Migration[5.0]
  def change
    remove_column :flights, :airport_departure_id
    remove_column :flights, :airport_arrival_id
  end
end
