class CreateOdZones < ActiveRecord::Migration[5.0]
  def change
    create_table :od_zones do |t|
      t.string :name, null: false
      t.string :description
      t.references :agency, foreign_key: true, null: false
      t.timestamps
    end
  end
end
