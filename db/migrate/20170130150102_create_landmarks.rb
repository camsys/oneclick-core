class CreateLandmarks < ActiveRecord::Migration[5.0]
  def change
    create_table :landmarks do |t|

      t.timestamps
    end
  end
end
