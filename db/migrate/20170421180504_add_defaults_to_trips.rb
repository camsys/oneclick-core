class AddDefaultsToTrips < ActiveRecord::Migration[5.0]
  def change
    change_column :trips, :trip_time, :datetime, default: DateTime.now.in_time_zone
    change_column :trips, :arrive_by, :boolean, default: false
  end
end
