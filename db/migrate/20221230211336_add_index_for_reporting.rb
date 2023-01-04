class AddIndexForReporting < ActiveRecord::Migration[5.0]
  def change
    add_index :bookings, :created_in_1click
    add_index :itineraries, :trip_type
    add_index :request_logs, :created_at
  end
end
