class AddRegionToOdZones < ActiveRecord::Migration[5.0]
  def change
    add_reference :od_zones, :region, references: :regions, index: true
    add_foreign_key :od_zones, :regions, column: :region_id
  end
end
