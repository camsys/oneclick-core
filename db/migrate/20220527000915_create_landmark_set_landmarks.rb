class CreateLandmarkSetLandmarks < ActiveRecord::Migration[5.0]
  def change
    create_table :landmark_set_landmarks do |t|
      t.references :landmark_set, foreign_key: true, null: false
      t.references :landmark, foreign_key: true, null: false

      t.timestamps
    end
  end
end
