class AddEcolaneErrorMessageToBookings < ActiveRecord::Migration[5.0]
  def change
    add_column :bookings, :ecolane_error_message, :text
  end
end