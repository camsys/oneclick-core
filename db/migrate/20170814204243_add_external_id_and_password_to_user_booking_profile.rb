class AddExternalIdAndPasswordToUserBookingProfile < ActiveRecord::Migration[5.0]
  def change
    add_column :user_booking_profiles, :encrypted_external_password, :string
    add_column :user_booking_profiles, :encrypted_external_password_iv, :string # Needed for attr_encrypted
    add_column :user_booking_profiles, :external_user_id, :string
    add_index :user_booking_profiles, :external_user_id
  end
end
