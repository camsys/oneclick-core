class AddCountyParatransitToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :county, :string 
    add_column :users, :paratransit_id, :string 
  end
end
