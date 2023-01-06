class AddFieldsToPurposes < ActiveRecord::Migration[5.0]
  def change
    add_column :purposes, :name, :string, null: false, default: ''
    add_column :purposes, :description, :string
    add_reference :purposes, :agency, foreign_key: true

    change_column_null :purposes, :code, true
  end
end
