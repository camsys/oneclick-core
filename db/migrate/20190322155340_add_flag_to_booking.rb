class AddFlagToBooking < ActiveRecord::Migration[5.0]
  def change
    add_column :bookings, :created_in_1click, :boolean, default: false
  end
end
