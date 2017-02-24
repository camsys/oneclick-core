class ServiceHasManyItineraries < ActiveRecord::Migration[5.0]
  def change
    add_reference :itineraries, :service, index: true, foreign_key: true
  end
end
