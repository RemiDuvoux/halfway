class AddIataToCities < ActiveRecord::Migration[5.0]
  def change
    add_column :cities, :iata_code, :string
  end
end
