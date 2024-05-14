class AddDispositionStatusToEcolaneBookingSnapshots < ActiveRecord::Migration[5.0]
  def change
    add_column :ecolane_booking_snapshots, :disposition_status, :string
    add_index :ecolane_booking_snapshots, :disposition_status
  end
end