class AddTimeWindowsToBooking < ActiveRecord::Migration[5.0]
  def change
    add_column :bookings, :earliest_pu, :datetime
    add_column :bookings, :latest_pu, :datetime
  end
end
