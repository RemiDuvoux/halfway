class AddPriceToTrips < ActiveRecord::Migration[5.0]
  def change
    add_column :trips, :price, :decimal
  end
end
