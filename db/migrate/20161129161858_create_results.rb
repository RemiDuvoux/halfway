class CreateResults < ActiveRecord::Migration[5.0]
  def change
    create_table :results do |t|
      t.string :city_a
      t.string :city_b
      t.date :date_there
      t.date :date_back

      t.timestamps
    end
  end
end
