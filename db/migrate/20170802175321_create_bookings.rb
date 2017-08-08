class CreateBookings < ActiveRecord::Migration[5.0]
  def change
    create_table :bookings do |t|
      t.references :itinerary, foreign_key: true
      t.string :type # Booking API Type
      t.string :status
      t.string :confirmation
      t.text :details

      t.timestamps
    end
  end
end
