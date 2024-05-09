class AddFundingAndPurposeToEcolaneBookingSnapshots < ActiveRecord::Migration[5.0]
  def change
    add_column :ecolane_booking_snapshots, :funding_source, :string
    add_column :ecolane_booking_snapshots, :purpose, :string
  end
end
