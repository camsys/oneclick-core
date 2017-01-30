class CreateConfigs < ActiveRecord::Migration[5.0]
  def change
    create_table :configs do |t|

      t.timestamps
    end
  end
end
