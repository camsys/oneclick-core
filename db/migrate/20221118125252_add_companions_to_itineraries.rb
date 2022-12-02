class AddCompanionsToItineraries < ActiveRecord::Migration[5.0]
  def change
    add_column :itineraries, :assistant, :boolean
    add_column :itineraries, :companions, :integer
  end
end
