class Trip < ApplicationRecord

  ### INSTANCE ATTRIBUTES ###
  attr_accessor :no_valid_services

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
  has_one :selected_service, through: :selected_itinerary, source: :service
  belongs_to :previous_trip, class_name: "Trip", foreign_key: :previous_trip_id
  has_one    :next_trip,     class_name: "Trip", foreign_key: :previous_trip_id, dependent: :nullify 
  has_many :oversight_agencies, through: :user

  has_many :trip_accommodations
  has_many :relevant_accommodations, class_name: "Accommodation", through: :trip_accommodations, source: :accommodation
  has_many :trip_eligibilities
  has_many :relevant_eligibilities, class_name: "Eligibility", through: :trip_eligibilities, source: :eligibility
  has_many :trip_purposes
  has_many :relevant_purposes, class_name: "Purpose", through: :trip_purposes, source: :purpose
  
  accepts_nested_attributes_for :origin
  accepts_nested_attributes_for :destination
  
  before_validation :set_trip_time
  serialize :details

  write_to_csv with: Admin::TripsReportCSVWriter

  ### VALIDATIONS ###
  validates_presence_of :origin, :destination, :trip_time

  ### CONSTANTS ###
  # Constant list of trip types that can be planned.
  TRIP_TYPES = [
    :transit, 
    :paratransit,
    # :car_park, # This trip type is not selectable. Instead, it is automatically included when both :car and :transit are selected
    :taxi,
    :walk,
    :car,
    :bicycle,
    # :uber, # commenting out since API has changed
    # :lyft # commenting out since API has changed
  ]
  DEFAULT_TRIP_DETAILS = { notification_preferences: nil}

  # Constant list of bad cities and the correct city
  CORRECTED_CITIES_HASHES = [
    { incorrect: 'West Manchester Township', correct: 'York'}, 
    { incorrect: 'West Manchester Twp', correct: 'York'}, 
    { incorrect: 'Hampden Township', correct: 'Mechanicsburg'},
    { incorrect: 'Hampden Twp', correct: 'Mechanicsburg'}
  ]
  BAD_CITIES = CORRECTED_CITIES_HASHES.map{|h| h[:incorrect]}

  # Trip disposition means trip request, so if I save a transit trip, that's a transit trip disposition
  DISPOSITION_STATUSES = {
    unknown: 'Unknown Disposition',
    fixed_route_saved: 'Saved fixed route trip',
    fixed_route_denied: 'Fixed route denial',
    ecolane_booked: 'Successfully booked in Ecolane',
    ecolane_denied: 'Ecolane booking denial'
  }


  ### SCOPES ###
  # Trips where users under an input transportation agency
  # Unused scope. Commenting it out for now.
  # scope :with_transportation_agency, -> (agency_id) {
  #   self.joins("LEFT JOIN traveler_transit_agencies on trips.user_id = traveler_transit_agencies.user_id")
  #       .merge(TravelerTransitAgency.where(transportation_agency_id: agency_id))
  # }
  
  # Trips with no transportation agency
  # Unused scope. Commenting it out for now.
  # scope :with_no_transportation_agency, -> {
  #   self.joins("LEFT JOIN traveler_transit_agencies on trips.user_id = traveler_transit_agencies.user_id")
  #       .merge(TravelerTransitAgency.where(transportation_agency_id: nil))
  # }

  scope :with_transportation_agency_or_guest_user, -> (agency_id) {
    self.joins("LEFT JOIN traveler_transit_agencies on trips.user_id = traveler_transit_agencies.user_id")
        .merge(TravelerTransitAgency.where(transportation_agency_id: [nil, *agency_id]))
  }

  # Return trips before or after a given date and time
  scope :from_datetime, -> (datetime) { datetime ? where('trip_time >= ?', datetime) : all }
  scope :to_datetime, -> (datetime) { datetime ? where('trip_time <= ?', datetime) : all }
  
  # Rounds to beginning or end of day.
  scope :from_date, -> (date) { date ? from_datetime(date.in_time_zone.beginning_of_day) : all }
  scope :to_date, -> (date) { date ? to_datetime(date.in_time_zone.end_of_day) : all }

  # Past trips have trip time before now, ordered from last to first; future
  # trips have trip time now and forward, ordered from first to last.
  scope :past, -> { where('trip_time < ?', DateTime.now.in_time_zone - 6.hours).order('trip_time DESC') }
  scope :past_14_days, -> { where('trip_time >= ?', DateTime.now.in_time_zone - 6.hours - 14.days).order('trip_time DESC') }
  scope :future, -> { where('trip_time >= ?', DateTime.now.in_time_zone - 6.hours).order('trip_time ASC') }

  # Select trips that are saved
  scope :selected, -> { where.not(selected_itinerary_id: nil) }

  # Geographic scopes return trips that start or end in the passed geom
  # The geom parameter does not always serialize correctly to the geometry type, so converting to text.
  scope :origin_in, -> (region_id) {
    joins(:origin).where('ST_Within(waypoints.geom, (SELECT geom FROM regions WHERE id = 2))', region_id)
  }
  
  scope :destination_in, -> (region_id) {
    joins(:destination).where('ST_Within(waypoints.geom, (SELECT geom FROM regions WHERE id = 2))', region_id)
  }
  
  # Returns trip that have any of the given purposes
  scope :with_purpose, -> (purposes) do
    where(id: where(external_purpose: purposes).pluck(:id))
  end

  # Return trips that are transit trips
  scope :transit_trips, -> {
    joins('inner join itineraries on itineraries.id = trips.selected_itinerary_id').where({ 'itineraries.trip_type': 'transit'})
  }

  # Return trips in the next n days
  # Note: this is not selecting trips that are in 7 days or less from now
  scope :in_next_n_days, ->(n_days) {
                            where({
                                  trip_time: (
                                    (DateTime.now.in_time_zone.midnight.to_time + n_days * 60 * 24).to_datetime.midnight..
                                      (DateTime.now.in_time_zone.midnight.to_time + (n_days + 1) * 60 * 60 * 24).to_datetime.midnight),
                                })}
  
  # Scopes based on trip linkages
  scope :outbound, -> do # Outbound trips: the first leg
    where(previous_trip_id: nil)  # Trips with no previous trip
  end
  scope :return, -> do  # Return trips: the last leg
    where.not(previous_trip_id: nil) # Trips with a previous trip...
    .where.not(id: Trip.pluck(:previous_trip_id)) # ...but NO next trip
  end
  scope :connecting, -> do # Connecting trips: the middle legs
    where.not(previous_trip_id: nil) # Trips with a previous trip...
    .where(id: Trip.pluck(:previous_trip)) # ...AND a next trip
  end

  # Scopes based on user
  scope :oversight_agency_in, -> (oversight_agency) do
    where(user_id: oversight_agency.staff_and_admins.pluck(:id))
  end

  # Scopes based on user
  scope :partner_agency_in, -> (partner_agency) do
    where(user_id: partner_agency.staff_and_admins.pluck(:id))
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
  
  # Attempts to get the trip_type from the selected itinerary
  def trip_type
    selected_itinerary.try(:trip_type).try(:to_sym)
  end
  
  # Attempts to get an arrival time based on the selected itinerary's end_time.
  def arrival_time
    selected_itinerary.try(:end_time) || trip_time
  end
    
  # Builds a next trip with origin and destination swapped, and departure
  # time set based on passed delay option. Defaults to depart at the end_time
  # of the selected itinerary. Accepts an optional options hash within attrs.
  def build_return_trip(attrs={})
    options = attrs.delete(:options) || {}
    duration = options[:duration] || 0.hours # Optional trip duration param delays return trip time
    build_next_trip({
      origin: destination, 
      destination: origin,
      user: user,
      purpose: purpose,
      arrive_by: false,
      trip_time: arrival_time + duration
    }.merge(attrs))
  end
  
  private
  
  # Sets trip time to current time, unless already set
  def set_trip_time
    self.trip_time = self.trip_time || DateTime.now.in_time_zone
  end
  

end
