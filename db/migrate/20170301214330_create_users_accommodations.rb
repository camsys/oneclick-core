class CreateUsersAccommodations < ActiveRecord::Migration[5.0]
  def change
    create_join_table :users, :accommodations do |t|
      t.index :user_id
      t.index :accommodation_id
    end
  end
end
