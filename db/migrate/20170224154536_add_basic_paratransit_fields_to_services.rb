class AddBasicParatransitFieldsToServices < ActiveRecord::Migration[5.0]
  def change
    add_column :services, :email, :string
    add_column :services, :url, :string
    add_column :services, :phone, :string
  end
end
