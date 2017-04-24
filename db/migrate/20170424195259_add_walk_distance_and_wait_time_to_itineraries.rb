class AddWalkDistanceAndWaitTimeToItineraries < ActiveRecord::Migration[5.0]
  def change
    add_column :itineraries, :walk_distance, :float
    add_column :itineraries, :wait_time, :integer
  end
end
