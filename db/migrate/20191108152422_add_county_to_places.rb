class AddCountyToPlaces < ActiveRecord::Migration[5.0]
  def change
    add_column :waypoints, :county, :string
    add_column :stomping_grounds, :county, :string 
    add_column :landmarks, :county, :string 
  end
end
