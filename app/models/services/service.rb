class Service < ApplicationRecord

  ### Includes ###
  mount_uploader :logo, LogoUploader
  include ScheduleHelper

  ### Associations ###
  has_many :itineraries
  has_many :schedules
  has_and_belongs_to_many :accommodations
  has_and_belongs_to_many :eligibilities
  belongs_to :start_or_end_area, class_name: 'Region', foreign_key: :start_or_end_area_id, dependent: :destroy
  belongs_to :trip_within_area, class_name: 'Region', foreign_key: :trip_within_area_id, dependent: :destroy
  accepts_nested_attributes_for :start_or_end_area, :trip_within_area

  ### Validations ###
  validates_presence_of :name, :type

  ### Scopes ###
  scope :available_for_rb, -> (trip) { self.select {|service| service.available_for?(trip)} }
  scope :available_for, -> (trip) do
    available_by_geography_for(trip)
    .available_for_user(trip.user)
    .available_by_time_for(trip)
  end
  scope :transit_services, -> { where(type: "Transit") }
  scope :paratransit_services, -> { where(type: "Paratransit") }
  scope :taxi_services, -> { where(type: "Taxi") }

  # Secondary Scopes #
  scope :available_for_user, -> (user) { user ? accepts_eligibility_of(user).accommodates(user) : all }
  scope :available_by_time_for, -> (trip) { available_by_schedule_for(trip) }
  scope :available_by_geography_for, -> (trip) do
    available_by_start_or_end_area_for(trip)
    .available_by_trip_within_area_for(trip)
  end

  # Tertiary Scopes #

  # available_for_user scopes
  scope :accommodates_by_code, -> (code) { joins(:accommodations).where(accommodations: {code: code}) }
  scope :accommodates, -> (user) do
    if user.accommodations.empty?
      all
    else
      where(id: accommodates_all_needs(user))
    end
  end
  scope :accepts_eligibility_of, -> (user) do
    # Either no eligibilities are set, or the user meets an eligibility requirement
    where( id: no_eligibilities | with_met_eligibilities(user) )
  end

  # available_by_time_for scopes
  scope :available_by_schedule_for, -> (trip) do
    # Either no schedules are set, or there is a schedule that includes the trip time
    where( id: no_schedules | with_matching_schedule(trip) )
  end

  # available_by_geography_for scopes
  scope :available_by_start_or_end_area_for, -> (trip) do
    # no start_or_end_area, or start_or_end_area contains origin OR destination
    where( id: no_region(:start_or_end_area) | with_containing_start_or_end_area(trip) )
  end
  scope :available_by_trip_within_area_for, -> (trip) do
    # no trip_within_area, or trip_within_area contains origin OR destination
    where( id: no_region(:trip_within_area) | with_containing_trip_within_area(trip) )
  end

  #################
  # CLASS METHODS #
  #################

  ### CONSTANTS ###
  SERVICE_TYPES = ['Transit', 'Paratransit', 'Taxi']


  ####################
  # INSTANCE METHODS #
  ####################

  # Returns true if service is available to serve the passed trip and its user
  # Most other methods feed into this one
  def available_for?(trip)
    available_for_user?(trip.user) &&
    available_by_geography_for?(trip) &&
    available_by_schedule_for?(trip)
  end


  ### AVAILABLE_FOR_USER? HELPER METHODS ###

  # Returns true if service accommodates all of the user's needs.
  def accommodates?(user)
    return true if user.nil?
    (user.accommodations.pluck(:code) - self.accommodations.pluck(:code)).empty?
  end

  # Returns true if user meets all of the service's eligibility requirements.
  def accepts_eligibility_of?(user)
    return true if user.nil?
    !(self.eligibilities.pluck(:code) & user.confirmed_eligibilities.pluck(:code)).empty?
  end


  ### AVAILABLE_BY_GEOGRAPHY_FOR? HELPER METHODS ###

  # Returns true if trip origin OR destination are in start or end area, or area is not set
  def available_by_start_or_end_area_for?(trip)
    start_or_end_area.nil? ||
    (start_or_end_area.contains?(trip.origin) ||
    start_or_end_area.contains?(trip.destination))
  end

  # Returns true if trip origin AND destination are in trip within area, or area is not set
  def available_by_trip_within_area_for?(trip)
    trip_within_area.nil? ||
    (trip_within_area.contains?(trip.origin) &&
    trip_within_area.contains?(trip.destination))
  end


  ### AVAILABLE_BY_SCHEDULE_FOR? HELPER METHODS ###

  # Return true if trip_time falls within set schedules
  def available_by_schedule_for_trip_time?(trip)
    wday = trip.trip_time.wday
    schedules.any? {|s| s.include?(trip.trip_time) }
  end

  ### IMPLEMENTATION METHODS ###
  # Overwrite these in subclasses

  # OVERWRITE
  # Returns true if user meets all accoomodation and eligibility requirements
  def available_for_user?(user)
    accepts_eligibility_of?(user) && accommodates?(user)
  end

  # OVERWRITE
  # Returns true if trip falls within service coverage areas.
  def available_by_geography_for?(trip)
    true
  end

  # OVERWRITE
  # Returns true if trip time meets service schedule requirements
  def available_by_schedule_for?(trip)
    true
  end

  # OVERWRITE
  # Builds geographic associations.
  def build_geographies
    nil
  end

  private

  ### SCOPE HELPER METHODS ###

  # Returns IDs of Services with no eligibility requirements
  def self.no_eligibilities
    includes(:eligibilities).where(eligibilities: {id: nil}).pluck(:id)
  end

  # Returns IDs of Services with at least one eligibility requirement met by user
  def self.with_met_eligibilities(user)
    joins(:eligibilities).where(eligibilities: {code: user.eligibilities.pluck(:code)}).pluck(:id)
  end

  # Returns IDs of Services that accommodate all of a user's needs
  def self.accommodates_all_needs(user)
    user.accommodations.pluck(:code).map {|code| Service.accommodates_by_code(code).pluck(:id)}.reduce(&:&)
  end

  # Returns IDs of Services with no schedules set
  def self.no_schedules
    includes(:schedules).where(schedules: {id: nil}).pluck(:id)
  end

  # Returns IDs of Services with a schedule that includes the trip time
  def self.with_matching_schedule(trip)
    joins(:schedules).where(schedules: {
      day: trip.wday,
      start_time: 0..trip.secs,
      end_time: trip.secs..DAY_LENGTH
    }).pluck(:id)
  end

  # Returns IDs of Services with no region of given association type
  def self.no_region(region_type)
    includes(region_type).where(regions: { id: nil }).pluck(:id)
  end

  # Returns IDs of Services with a start_or_end_area containing trip origin OR destination
  def self.with_containing_start_or_end_area(trip)
    region_contains(:start_or_end_area, Trip.last.origin.to_point)
    .or(region_contains(:start_or_end_area, Trip.last.destination.to_point))
    .pluck(:id)
  end

  # Returns IDs of Services with a trip_within_area containing trip origin AND destination
  def self.with_containing_trip_within_area(trip)
    region_contains(:trip_within_area, Trip.last.origin.to_point)
    .region_contains(:trip_within_area, Trip.last.destination.to_point)
    .pluck(:id)
  end

  # Helper scope constructs a contains query based on region association name and a geometry
  scope :region_contains, -> (region, geom) do
    joins(region).where("ST_CONTAINS(regions.geom, ?)", geom.to_s)
  end


end
