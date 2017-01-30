class AddOriginDestinationToTrips < ActiveRecord::Migration[5.0]
  def change
  	add_reference :trips, :origin, references: :places, index: true
  	add_foreign_key :trips, :places, column: :origin_id

  	add_reference :trips, :destination, references: :places, index: true
  	add_foreign_key :trips, :places, column: :destination_id
  end
end
