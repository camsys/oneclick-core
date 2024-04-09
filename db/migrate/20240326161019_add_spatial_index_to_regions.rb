class AddSpatialIndexToRegions < ActiveRecord::Migration[5.0]
  def change
    add_index :regions, :geom, using: :gist
  end
end
