class CreateAlerts < ActiveRecord::Migration[5.0]
  def change
    create_table :alerts do |t|
      t.datetime :expiration
      t.string :audience, default: :everyone, null: false
      t.boolean :published, default: true, null: false
      t.text :audience_details
      t.timestamps
    end
  end
end
