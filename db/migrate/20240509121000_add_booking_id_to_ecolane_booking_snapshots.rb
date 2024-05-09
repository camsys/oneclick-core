class AddBookingIdToEcolaneBookingSnapshots < ActiveRecord::Migration[5.0]
  def change
    add_reference :ecolane_booking_snapshots, :booking, foreign_key: true
  end
end