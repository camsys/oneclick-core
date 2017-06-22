class ConvertAllGeomColumnsToSrid4326 < ActiveRecord::Migration[5.0]
  def change
    
    # CITIES
    remove_column :cities, :geom, :geometry
    add_column :cities, :geom, :geometry, srid: 4326
    
    # COUNTIES
    remove_column :counties, :geom, :geometry
    add_column :counties, :geom, :geometry, srid: 4326
    
    # CUSTOM GEOGRAPHIES
    remove_column :custom_geographies, :geom, :geometry
    add_column :custom_geographies, :geom, :geometry, srid: 4326
    
    # ZIPCODES
    remove_column :zipcodes, :geom, :geometry
    add_column :zipcodes, :geom, :geometry, srid: 4326
    
    # REGIONS
    remove_column :regions, :geom, :multi_polygon
    add_column :regions, :geom, :multi_polygon, srid: 4326
    
  end
end
