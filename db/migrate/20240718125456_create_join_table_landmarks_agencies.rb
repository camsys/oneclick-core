class CreateJoinTableLandmarksAgencies < ActiveRecord::Migration[5.0]
  def change
    create_join_table :landmarks, :agencies do |t|
      t.index :landmark_id
      t.index :agency_id
      t.foreign_key :landmarks
      t.foreign_key :agencies
    end
  end
end
