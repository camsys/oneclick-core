class AddOldToLandmark < ActiveRecord::Migration[5.0]
  def change
  	add_column :landmarks, :old, :boolean
  end
end
