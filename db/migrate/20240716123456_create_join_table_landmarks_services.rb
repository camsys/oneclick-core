class CreateJoinTableLandmarksServices < ActiveRecord::Migration[6.0]
  def change
    create_join_table :landmarks, :services do |t|
      t.index :landmark_id
      t.index :service_id
    end
  end
end