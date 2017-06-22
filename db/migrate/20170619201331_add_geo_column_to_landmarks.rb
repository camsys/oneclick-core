class AddGeoColumnToLandmarks < ActiveRecord::Migration[5.0]
  def change
    
    add_column :landmarks, :geom, :st_point, srid: 4326 
    add_index :landmarks, :geom, using: :gist
    
  end
end
