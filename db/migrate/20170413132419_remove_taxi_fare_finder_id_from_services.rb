class RemoveTaxiFareFinderIdFromServices < ActiveRecord::Migration[5.0]
  def change
  	remove_column :services, :taxi_fare_finder_id, :string
  end
end
