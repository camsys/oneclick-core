class Itinerary < ApplicationRecord
  belongs_to :trip
  belongs_to :service
  has_one :selecting_trip, foreign_key: "selected_itinerary_id", class_name: "Trip"
  has_one :uber_extension, dependent: :destroy

  serialize :legs

  ### Scopes ###
  scope :transit_itineraries, -> { joins(:service).where('services.type = ?', 'Transit') }
  scope :paratransit_itineraries, -> { joins(:service).where('services.type = ?', 'Paratransit') }
  scope :taxi_itineraries, -> { joins(:service).where('services.type = ?', 'Taxi') }

  before_save :calculate_start_and_end_time

  # Duration virtual attribute sums all trip_time attributes
  def duration # (in seconds)
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

  # Calculates start and end time based on arrive_by, trip_time, and duration
  def calculate_start_and_end_time
    return false if trip.nil?

    if self.start_time.nil?
      self.start_time = trip.arrive_by ? trip.trip_time - duration : trip.trip_time
    end

    if self.end_time.nil?
      self.end_time = trip.arrive_by ? trip.trip_time : trip.trip_time + duration
    end
  end

end
