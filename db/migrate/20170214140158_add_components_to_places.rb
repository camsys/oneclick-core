class AddComponentsToPlaces < ActiveRecord::Migration[5.0]
  def change
    add_column :places, :name, :string
    add_column :places, :street_number, :string
    add_column :places, :route, :string
    add_column :places, :city, :string
    add_column :places, :state, :string
    add_column :places, :zip, :string
    add_column :places, :lat, :decimal, precision: 10, scale: 6
    add_column :places, :lng, :decimal, precision: 10, scale: 6
  end
end
