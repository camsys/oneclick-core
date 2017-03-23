class AddSelectedItineraryToTrip < ActiveRecord::Migration[5.0]
  def change
    add_reference :trips, :selected_itinerary, references: :itineraries, index: true
  	add_foreign_key :trips, :itineraries, column: :selected_itinerary_id

  end
end
