class CreateCities < ActiveRecord::Migration[5.0]
  def change
    create_table :cities do |t|
      t.string :name
      t.string :state
      t.geometry :geom

      t.timestamps
    end

    change_table :cities do |t|
      t.index :geom, using: :gist
    end
  end
end
