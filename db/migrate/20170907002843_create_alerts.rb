class CreateAlerts < ActiveRecord::Migration[5.0]
  def change
    create_table :alerts do |t|
      t.datetime :expiration
      t.string :audience, default: :EVERYONE, null: false
      t.boolean :published, default: true, null: false
      t.timestamps
    end
  end
end
