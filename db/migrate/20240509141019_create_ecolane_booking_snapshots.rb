class CreateEcolaneBookingSnapshots < ActiveRecord::Migration[5.0]
  def change
    create_table :ecolane_booking_snapshots do |t|
      t.integer :itinerary_id
      t.string :type
      t.string :status
      t.string :confirmation
      t.text :details
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :earliest_pu
      t.datetime :latest_pu
      t.datetime :negotiated_pu
      t.datetime :negotiated_do
      t.datetime :estimated_pu
      t.datetime :estimated_do
      t.boolean :created_in_1click, default: false
      t.text :note

      t.timestamps
    end

    add_index :ecolane_booking_snapshots, :booking_id
  end
end