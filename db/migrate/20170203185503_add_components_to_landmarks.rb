class AddComponentsToLandmarks < ActiveRecord::Migration[5.0]
  def change
  	add_column :landmarks, :name, :string
  	add_column :landmarks, :street_number, :string
  	add_column :landmarks, :route, :string 
  	add_column :landmarks, :types, :text
  	add_column :landmarks, :address, :string
  	add_column :landmarks, :city, :string
  	add_column :landmarks, :state, :string
  	add_column :landmarks, :zip, :string
  	add_column :landmarks, :lat, :string
  	add_column :landmarks, :lng, :string
  end
end
