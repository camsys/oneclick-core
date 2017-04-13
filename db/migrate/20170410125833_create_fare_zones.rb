class CreateFareZones < ActiveRecord::Migration[5.0]
  def change
    create_table :fare_zones do |t|
      t.integer :service_id
      t.integer :region_id
      t.string :code

      t.timestamps
    end

    add_index :fare_zones, [:service_id, :region_id]
  end
end
