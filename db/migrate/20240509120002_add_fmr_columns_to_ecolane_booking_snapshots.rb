class AddFmrColumnsToEcolaneBookingSnapshots < ActiveRecord::Migration[5.0]
  def change
    change_table :ecolane_booking_snapshots do |t|
      t.string :traveler
      t.string :orig_addr
      t.float :orig_lat
      t.float :orig_lng
      t.string :dest_addr
      t.float :dest_lat
      t.float :dest_lng
      t.string :agency_name
      t.string :service_name
      t.integer :booking_client_id
      t.boolean :is_round_trip
      t.string :sponsor
      t.integer :companions
      t.string :ecolane_error_message
      t.boolean :pca
    end
  end
end
