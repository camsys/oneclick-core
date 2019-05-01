class AddNegotiatedTimesToBooking < ActiveRecord::Migration[5.0]
  def change
    add_column :bookings, :negotiated_pu, :datetime
    add_column :bookings, :negotiated_do, :datetime
  end
end
