class AddNoteToBookings < ActiveRecord::Migration[5.0]
  def change
    add_column :bookings, :note, :text
  end
end