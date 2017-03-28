class Service < ApplicationRecord

  ### Includes ###
  mount_uploader :logo, LogoUploader
  include ScheduleHelper
  include ScopeHelper

  ### ASSOCIATIONS ###
  has_many :itineraries
  has_many :schedules
  has_and_belongs_to_many :accommodations
  has_and_belongs_to_many :eligibilities
  belongs_to :start_or_end_area, class_name: 'Region', foreign_key: :start_or_end_area_id, dependent: :destroy
  belongs_to :trip_within_area, class_name: 'Region', foreign_key: :trip_within_area_id, dependent: :destroy

  ### VALIDATIONS ###
  validates_presence_of :name, :type


  ##########
  # SCOPES #
  ##########

  ## Primary Scopes ##
  scope :available_for, -> (trip) do
    available_by_geography_for(trip)
    .available_for_user(trip.user)
    .available_by_time_for(trip)
  end
  scope :transit_services, -> { where(type: "Transit") }
  scope :paratransit_services, -> { where(type: "Paratransit") }
  scope :taxi_services, -> { where(type: "Taxi") }

  ## Secondary Scopes ##
  scope :available_for_user, -> (user) { user ? accepts_eligibility_of(user).accommodates(user) : all }
  scope :available_by_time_for, -> (trip) { available_by_schedule_for(trip) }
  scope :available_by_geography_for, -> (trip) do
    available_by_start_or_end_area_for(trip)
    .available_by_trip_within_area_for(trip)
  end

  ## Tertiary Scopes ##
  # available_for_user scopes
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

  # Builds instance methods for determining if record falls within given scope
  build_instance_scopes :available_for,
    :available_for_user, :available_by_time_for, :available_by_geography_for,
    :accommodates, :accepts_eligibility_of,
    :available_by_schedule_for,
    :available_by_start_or_end_area_for, :available_by_trip_within_area_for


  #################
  # CLASS METHODS #
  #################

  ### CONSTANTS ###
  SERVICE_TYPES = ['Transit', 'Paratransit', 'Taxi']



  ####################
  # INSTANCE METHODS #
  ####################

  # OVERWRITE
  # Builds geographic associations.
  def build_geographies
    nil
  end


  # Silently filters out schedule params that don't meet criteria
  def reject_schedule?(attrs)
    attrs['day'].blank? || attrs['start_time'].blank? || attrs['end_time'].blank?
  end

  ###################
  private # PRIVATE #
  ###################


  ### SCOPE HELPER METHODS ###

  # Returns IDs of Services with no eligibility requirements
  def self.no_eligibilities
    includes(:eligibilities).where(eligibilities: {id: nil}).pluck(:id)
  end

  # Returns IDs of Services with at least one eligibility requirement met by user
  def self.with_met_eligibilities(user)
    joins(:eligibilities).where(eligibilities: {code: user.eligibilities.pluck(:code)}).pluck(:id)
  end

  # Returns all services that provide a given accommodation
  scope :accommodates_by_code, -> (code) { joins(:accommodations).where(accommodations: {code: code}) }

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

  # Returns IDs of Services with a start_or_end_area that is EMPTY or containing trip origin OR destination
  def self.with_containing_start_or_end_area(trip)
    joins(:start_or_end_area).empty_region(:start_or_end_area)
    .or(joins(:start_or_end_area).region_contains(Trip.last.origin.to_point))
    .or(joins(:start_or_end_area).region_contains(Trip.last.destination.to_point))
    .pluck(:id)
  end

  # Returns IDs of Services with a trip_within_area that is EMPTY or containing trip origin AND destination
  def self.with_containing_trip_within_area(trip)
    joins(:trip_within_area)
    .region_contains(Trip.last.origin.to_point)
    .region_contains(Trip.last.destination.to_point)
    .or(joins(:trip_within_area).empty_region(:trip_within_area))
    .pluck(:id)
  end

  # Helper scope constructs a contains query based on region association name and a geometry
  scope :region_contains, -> (geom) do
    where("ST_Contains(regions.geom, ?)", geom.to_s)
  end

  # Helper scope constructs a query for empty regions
  scope :empty_region, -> (region) do
    where("ST_IsEmpty(regions.geom)")
  end

end
