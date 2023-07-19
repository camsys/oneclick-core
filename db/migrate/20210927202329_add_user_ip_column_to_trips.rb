class AddUserIpColumnToTrips < ActiveRecord::Migration[5.0]
  def change
    add_column :trips, :user_ip, :inet
  end
end
