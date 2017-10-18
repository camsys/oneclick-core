class RemoveDefaultTripTime < ActiveRecord::Migration[5.0]
  def change
    change_column_default :trips, :trip_time, nil
  end
end
