class AddSimplifiedGeomToRegions < ActiveRecord::Migration[5.0]
  def change
    add_column :regions, :simplified_geom, :geometry, limit: { srid: 4326, type: 'multi_polygon' }
    add_index :regions, :simplified_geom, using: :gist
  end
end
