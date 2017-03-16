class AddIndexesToGeoTables < ActiveRecord::Migration[5.0]
  def change
    add_index :counties, [:name, :state]
    add_index :zipcodes, :name
    add_index :cities, [:name, :state]
  end
end
