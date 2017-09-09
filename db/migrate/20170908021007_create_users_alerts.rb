class CreateUsersAlerts < ActiveRecord::Migration[5.0]
  def change
    create_table :user_alerts do |t|
      t.boolean :acknowledged, null: false, default: false 
      t.integer :alert_id, null: false, references: [:alerts, :id]
      t.integer :user_id, null: false, references: [:users, :id]

      t.timestamps
    end
  end
end
