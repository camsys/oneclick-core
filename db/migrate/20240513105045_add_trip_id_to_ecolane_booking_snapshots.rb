class AddTripIdToEcolaneBookingSnapshots < ActiveRecord::Migration[5.0]
  def change
    add_column :ecolane_booking_snapshots, :trip_id, :integer
    add_index :ecolane_booking_snapshots, :trip_id
  end
end