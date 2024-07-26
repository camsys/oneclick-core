class CreateJoinTableLandmarksServices < ActiveRecord::Migration[5.0]
  def change
    create_join_table :landmarks, :services do |t|
      t.index :landmark_id
      t.index :service_id
      t.foreign_key :landmarks
      t.foreign_key :services
    end
  end
end
