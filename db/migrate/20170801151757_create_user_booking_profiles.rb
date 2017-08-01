class CreateUserBookingProfiles < ActiveRecord::Migration[5.0]
  def change
    create_table :user_booking_profiles do |t|
      t.references :user, foreign_key: true
      t.references :service, foreign_key: true
      t.string :booking_api
      t.text :details

      t.timestamps
    end
  end
end
