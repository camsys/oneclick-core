class Trip < ApplicationRecord

  ### ASSOCIATIONS
  belongs_to :user
  has_many :itineraries, dependent: :destroy
  has_many :services, through: :itineraries
  belongs_to :origin, class_name: 'Waypoint', foreign_key: :origin_id, dependent: :destroy
  belongs_to :destination, class_name: 'Waypoint', foreign_key: :destination_id, dependent: :destroy
  belongs_to :selected_itinerary, class_name: "Itinerary", foreign_key: :selected_itinerary_id

  accepts_nested_attributes_for :origin
  accepts_nested_attributes_for :destination

  ### INSTANCE METHODS ###

  def unselect
    self.update(selected_itinerary: nil)
  end

  # Wrapper method returns the weekday of the trip time
  def wday
    trip_time.in_time_zone.wday
  end

  # Wrapper method returns seconds since midnight of trip time in local time zone
  def secs
    trip_time.in_time_zone.seconds_since_midnight
  end

end
