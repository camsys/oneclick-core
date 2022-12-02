class ConstrainCustomGeographyNameColumn < ActiveRecord::Migration[5.0]
  def change
    change_column :custom_geographies,:name,:string, unique: true
  end
end
