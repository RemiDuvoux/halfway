class CreateAirports < ActiveRecord::Migration[5.0]
  def change
    create_table :airports do |t|
      t.string :iata_code
      t.references :city, foreign_key: true

      t.timestamps
    end
  end
end
