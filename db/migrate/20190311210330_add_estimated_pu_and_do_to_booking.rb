class AddEstimatedPuAndDoToBooking < ActiveRecord::Migration[5.0]
  def change
    add_column :bookings, :estimated_pu, :datetime
    add_column :bookings, :estimated_do, :datetime
  end
end
