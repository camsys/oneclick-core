class RemoveBookingIdFromEcolaneBookingSnapshots < ActiveRecord::Migration[5.0]
  def change
    remove_column :ecolane_booking_snapshots, :booking_id, :integer
  end
end