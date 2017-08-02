class Trip < ApplicationRecord
  
  ### INCLUDES ###
  include BookingHelpers::TripHelpers
  
  
  ### ASSOCIATIONS ###
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

  attr_accessor :relevant_purposes, :relevant_eligibilities, :relevant_accommodations
  write_to_csv with: Admin::TripsReportCSVWriter

  ### VALIDATIONS ###
  validates_presence_of :origin, :destination

  ### CONSTANTS ###
  # Constant list of trip types that can be planned.
  TRIP_TYPES = [:transit, :paratransit, :taxi, :walk, :car, :bicycle, :uber]


  ### SCOPES ###

  # Return trips before or after a given date and time
  scope :from_datetime, -> (datetime) { datetime ? where('trip_time >= ?', datetime) : all }
  scope :to_datetime, -> (datetime) { datetime ? where('trip_time <= ?', datetime) : all }
  
  # Rounds to beginning or end of day.
  scope :from_date, -> (date) { date ? from_datetime(date.in_time_zone.beginning_of_day) : all }
  scope :to_date, -> (date) { date ? to_datetime(date.in_time_zone.end_of_day) : all }

  # Past trips have trip time before now, ordered from last to first; future
  # trips have trip time now and forward, ordered from first to last.
  scope :past, -> { where('trip_time < ?', DateTime.now.in_time_zone).order('trip_time DESC') }
  scope :future, -> { where('trip_time >= ?', DateTime.now.in_time_zone).order('trip_time ASC') }

  # Geographic scopes return trips that start or end in the passed geom
  scope :origin_in, -> (geom) do
    where(id: joins(:origin).where('ST_Within(waypoints.geom, ?)', geom).pluck(:id))
  end
  scope :destination_in, -> (geom) do
    where(id: joins(:destination).where('ST_Within(waypoints.geom, ?)', geom).pluck(:id))
  end
  
  # Returns trip that have any of the given purposes
  scope :with_purpose, -> (purpose_ids) do
    where(id: joins(:purpose).where(purposes: { id: purpose_ids }).pluck(:id))
  end
  
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
