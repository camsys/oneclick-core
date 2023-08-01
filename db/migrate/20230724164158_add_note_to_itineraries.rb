class AddNoteToItineraries < ActiveRecord::Migration[5.0]
  def change
    add_column :itineraries, :note, :string
  end
end
