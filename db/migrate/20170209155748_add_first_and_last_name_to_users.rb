class AddFirstAndLastNameToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_index :users, [:last_name, :first_name]
  end
end
