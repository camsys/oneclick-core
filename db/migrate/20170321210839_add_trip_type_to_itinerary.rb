class AddTripTypeToItinerary < ActiveRecord::Migration[5.0]
  def change
  	add_column :itineraries, :trip_type, :string
  end
end
