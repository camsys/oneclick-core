class CreateCounties < ActiveRecord::Migration[5.0]
  def change
    create_table :counties do |t|
      t.string :name
      t.string :state
      t.geometry :geom
      # t.geometry :geom, srid: 3785 # Use mercator projection
    end

    change_table :counties do |t|
      t.index :geom, using: :gist
    end

  end
end
