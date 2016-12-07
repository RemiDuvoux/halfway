class AddPictureToCities < ActiveRecord::Migration[5.0]
  def change
    add_column :cities, :photo_url, :string
  end
end
