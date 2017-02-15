class AddTripTimeAndArriveByToTrips < ActiveRecord::Migration[5.0]
  def change
    add_column :trips, :trip_time, :datetime
    add_column :trips, :arrive_by, :boolean
  end
end
