class AddAgesToServices < ActiveRecord::Migration[5.0]
  def change
    add_column :services, :max_age, :integer, null: false, default: 200
    add_column :services, :min_age, :integer, null: false, default: 0
    add_column :users, :age, :integer
  end
end
