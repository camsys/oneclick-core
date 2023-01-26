class AddOdZonesToTravelPatterns < ActiveRecord::Migration[5.0]
  def change
    add_reference :travel_patterns, :origin_zone, index: true
    add_foreign_key :travel_patterns, :od_zones, column: :origin_zone_id
    add_reference :travel_patterns, :destination_zone, index: true
    add_foreign_key :travel_patterns, :od_zones, column: :destination_zone_id
    add_column :travel_patterns, :allow_reverse_sequence_trips, :boolean, default: true, null: false
  end
end
