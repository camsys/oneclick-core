class AddActiveBookingProfileToUsers < ActiveRecord::Migration[5.0]
  def change
    add_reference :users, :active_booking_profile, references: :user_booking_profiles, index: true
    add_foreign_key :users, :user_booking_profiles, column: :active_booking_profile_id
  end
end
