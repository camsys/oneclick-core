class AddSpatialIndexToWaypoints < ActiveRecord::Migration[5.0]
  def change
    add_index :waypoints, :geom, using: :gist
  end
end
