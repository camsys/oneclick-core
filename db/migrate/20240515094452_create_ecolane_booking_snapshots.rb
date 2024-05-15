class CreateEcolaneBookingSnapshots < ActiveRecord::Migration[5.0]
  def change
    create_table :ecolane_booking_snapshots do |t|
      t.integer :itinerary_id
      t.string :status
      t.string :confirmation
      t.text :details
      t.datetime :earliest_pu
      t.datetime :latest_pu
      t.datetime :negotiated_pu
      t.datetime :negotiated_do
      t.datetime :estimated_pu
      t.datetime :estimated_do
      t.boolean :created_in_1click, default: false
      t.text :note
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
      t.string :funding_source
      t.string :purpose
      t.references :booking, foreign_key: true
      t.references :trip, foreign_key: true
      t.string :disposition_status

      t.timestamps
    end
  end
end
