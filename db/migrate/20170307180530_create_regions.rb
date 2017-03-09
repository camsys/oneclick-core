class CreateRegions < ActiveRecord::Migration[5.0]
  def change
    create_table :regions do |t|
      t.text :recipe
      t.geometry :geom

      t.timestamps
    end

    change_table :regions do |t|
      t.index :geom, using: :gist
    end
  end
end
