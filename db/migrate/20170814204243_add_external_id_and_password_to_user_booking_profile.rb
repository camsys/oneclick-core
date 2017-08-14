class AddExternalIdAndPasswordToUserBookingProfile < ActiveRecord::Migration[5.0]
  def change
    change_table :user_booking_profiles do |t|
      t.string :encrypted_external_password, null: false, default: ""
      t.string :external_user_id, null: false, default: ""
    end
    add_index :user_booking_profiles, :external_user_id
  end
end
