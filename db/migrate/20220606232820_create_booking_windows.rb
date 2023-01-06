class CreateBookingWindows < ActiveRecord::Migration[5.0]
  def change
    create_table :booking_windows do |t|
      t.references :agency, foreign_key: true, null: false
      t.references :travel_pattern, foreign_key: true
      t.string :name
      t.string :description
      t.integer :minimum_days_notice
      t.integer :maximum_days_notice
      t.integer :minimum_notice_cutoff_hour

      t.timestamps
    end

    add_reference :travel_patterns, :booking_window, foreign_key: true
  end
end
