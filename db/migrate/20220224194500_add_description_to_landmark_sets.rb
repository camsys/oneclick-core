class AddDescriptionToLandmarkSets < ActiveRecord::Migration[5.0]
  def change
    add_column :landmark_sets, :description, :text
  end
end
