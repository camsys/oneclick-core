class Trip < ApplicationRecord

  ### ASSOCIATIONS
  belongs_to :user
  has_many :itineraries, dependent: :destroy
  has_many :services, through: :itineraries
  has_many :purposes, through: :services
  belongs_to :purpose
  belongs_to :origin, class_name: 'Waypoint', foreign_key: :origin_id, dependent: :destroy
  belongs_to :destination, class_name: 'Waypoint', foreign_key: :destination_id, dependent: :destroy
  belongs_to :selected_itinerary, class_name: "Itinerary", foreign_key: :selected_itinerary_id

  accepts_nested_attributes_for :origin
  accepts_nested_attributes_for :destination

  attr_accessor :relevant_purposes, :relevant_eligibilites, :relevant_accommodations

  ### VALIDATIONS ###
  validates_presence_of :origin, :destination

  ### CONSTANTS ###
  # Constant list of trip types that can be planned.
  TRIP_TYPES = [:transit, :paratransit, :taxi, :walk, :car, :bicycle, :uber]

  ### SCOPES ###
  # Past trips have trip time before now, ordered from last to first; future
  # trips have trip time now and forward, ordered from first to last.
  scope :past, -> { where('trip_time < ?', DateTime.now.in_time_zone).order('trip_time DESC') }
  scope :future, -> { where('trip_time >= ?', DateTime.now.in_time_zone).order('trip_time ASC') }

  ### CLASS METHODS ###

  # Returns a collection of the waypoints (origins and destinations) associated with a trips collection
  def self.waypoints
    Waypoint.where(id: ods)
  end

  # Returns a list of the origin and destination ids associated with a trips collection
  def self.ods
    pluck(:origin_id, :destination_id).flatten.compact.uniq
  end


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
