class Itinerary < ApplicationRecord
  belongs_to :trip
  belongs_to :service
  has_one :selecting_trip, foreign_key: "selected_itinerary_id", class_name: "Trip"
  
  serialize :legs

  ### Scopes ###
  scope :transit_itineraries, -> { joins(:service).where('services.type = ?', 'Transit') }
  scope :paratransit_itineraries, -> { joins(:service).where('services.type = ?', 'Paratransit') }
  scope :taxi_itineraries, -> { joins(:service).where('services.type = ?', 'Taxi') }

  # Duration virtual attribute sums all trip_time attributes
  def duration
    (walk_time || 0) + (transit_time || 0) #+ wait_time
  end

  def select
    self.trip.update(selected_itinerary: self)
  end

  def unselect
    if self.selecting_trip
      self.selecting_trip.unselect
    else
      false
    end
  end

end
