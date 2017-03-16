class CreateCustomGeographies < ActiveRecord::Migration[5.0]
  def change
    create_table :custom_geographies do |t|
      t.string :name
      t.geometry :geom

      t.timestamps
    end

    change_table :custom_geographies do |t|
      t.index :geom, using: :gist
      t.index :name
    end
  end
end
