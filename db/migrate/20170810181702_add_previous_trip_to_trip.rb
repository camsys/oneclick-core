class AddPreviousTripToTrip < ActiveRecord::Migration[5.0]
  def change
    add_reference :trips, :previous_trip, index: true, foreign_key: { to_table: :trips }
  end
end
