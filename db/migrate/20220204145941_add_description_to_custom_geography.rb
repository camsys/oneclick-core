class AddDescriptionToCustomGeography < ActiveRecord::Migration[5.0]
  def change
    add_column :custom_geographies,:description,:text
  end
end
