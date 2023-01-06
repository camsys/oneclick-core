class CreateLandmarkSets < ActiveRecord::Migration[5.0]
  def change
    create_table :landmark_sets do |t|
      t.string :name, null: false, unique: true
    end
  end
end
