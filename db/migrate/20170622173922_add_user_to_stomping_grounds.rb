class AddUserToStompingGrounds < ActiveRecord::Migration[5.0]
  def change
  	add_reference :stomping_grounds, :user, foreign_key: true
  end
end
