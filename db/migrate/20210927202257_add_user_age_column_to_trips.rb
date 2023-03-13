class AddUserAgeColumnToTrips < ActiveRecord::Migration[5.0]
  def change
    add_column :trips, :user_age, :integer
  end
end
