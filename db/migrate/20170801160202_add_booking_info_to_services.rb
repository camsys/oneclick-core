class AddBookingInfoToServices < ActiveRecord::Migration[5.0]
  def change
    add_column :services, :booking_api, :string
    add_column :services, :booking_details, :text
  end
end
