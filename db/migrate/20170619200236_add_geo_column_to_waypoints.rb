class AddGeoColumnToWaypoints < ActiveRecord::Migration[5.0]
  def change
    
    add_column :waypoints, :geom, :st_point, srid: 4326
    add_index :waypoints, :geom, using: :gist
    
  end
end
