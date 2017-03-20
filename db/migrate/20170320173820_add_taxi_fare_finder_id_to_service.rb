class AddTaxiFareFinderIdToService < ActiveRecord::Migration[5.0]
  def change
  	add_column :services, :taxi_fare_finder_id, :string 
  end
end
