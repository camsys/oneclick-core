class AddNameAndGtfsIndexesToServices < ActiveRecord::Migration[5.0]
  def change
    add_index :services, :gtfs_agency_id
    add_index :services, :name
  end
end
