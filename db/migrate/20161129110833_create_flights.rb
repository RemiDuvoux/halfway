class CreateFlights < ActiveRecord::Migration[5.0]
  def change
    create_table :flights do |t|
      t.references :trip, foreign_key: true
      t.datetime :departure_time
      t.datetime :arrival_time
      t.integer :airport_departure_id, foreign_key: true
      t.integer :airport_arrival_id, foreign_key: true

      t.timestamps
    end
  end
end
