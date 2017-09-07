class CreateAlerts < ActiveRecord::Migration[5.0]
  def change
    create_table :alerts do |t|
      t.string :subject
      t.text :message
      t.datetime :expiration

      t.timestamps
    end
  end
end
