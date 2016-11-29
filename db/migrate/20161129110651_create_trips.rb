class CreateTrips < ActiveRecord::Migration[5.0]
  def change
    create_table :trips do |t|
      t.references :trip, foreign_key: true
      t.references :city, foreign_key: true

      t.timestamps
    end
  end
end
