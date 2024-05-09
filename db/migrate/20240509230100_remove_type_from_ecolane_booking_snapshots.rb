class RemoveTypeFromEcolaneBookingSnapshots < ActiveRecord::Migration[5.0]
  def change
    if column_exists?(:ecolane_booking_snapshots, :type)
      remove_column :ecolane_booking_snapshots, :type, :string
    end
  end
end
