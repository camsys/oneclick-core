class CreateStompingGrounds < ActiveRecord::Migration[5.0]
  def change
    create_table :stomping_grounds do |t|
      t.string   "name"
      t.string   "street_number"
      t.string   "route"
      t.string   "city"
      t.string   "state"
      t.string   "zip"
      t.boolean  "old"
      t.decimal  "lat", precision: 10, scale: 6
      t.decimal  "lng", precision: 10, scale: 6
      t.geometry "geom",          limit: {:srid=>4326, :type=>"st_point"}
      t.index ["geom"], name: "index_stomping_grounds_on_geom", using: :gist
      t.timestamps
    end
  end
end
