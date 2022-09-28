class RemoveConfirmationFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_index :users, :confirmation_token
    remove_column :users, :confirmation_token, :string
    remove_column :users, :confirmed_at, :datetime
    remove_column :users, :confirmation_sent_at, :datetime
  end
end
