class AddPreferredTripTypesToUser < ActiveRecord::Migration[5.0]
  def change
  	add_column :users, :preferred_trip_types, :text 
  end
end
