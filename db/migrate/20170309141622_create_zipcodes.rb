class CreateZipcodes < ActiveRecord::Migration[5.0]
  def change
    create_table :zipcodes do |t|
      t.string :name
      t.geometry :geom

      t.timestamps
    end

    change_table :zipcodes do |t|
      t.index :geom, using: :gist
    end
  end
end
