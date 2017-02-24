class AddTransitFieldsToItineraries < ActiveRecord::Migration[5.0]
  def change

    add_column :itineraries, :start_time, :datetime
    add_column :itineraries, :end_time, :datetime

    add_column :itineraries, :legs, :text

    add_column :itineraries, :walk_time, :integer
    add_column :itineraries, :transit_time, :integer

    add_column :itineraries, :cost, :float

  end
end
