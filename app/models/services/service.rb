class Service < ApplicationRecord

  ### INCLUDES ###
  mount_uploader :logo, LogoUploader
  include Archivable # SETS DEFAULT SCOPE TO where.not(archived: true)
  include Commentable # has_many :comments
  include FareHelper
  include FareHelper::ZoneFareable
  include GeoKitchen
  include ScheduleHelper
  include ScopeHelper
  include Feedbackable
  write_to_csv with: Admin::ServicesReportCSVWriter

  ### ATTRIBUTES & ASSOCIATIONS ###
  serialize :fare_details
  has_many :itineraries, dependent: :nullify
  has_many :schedules, dependent: :destroy
  has_many :feedbacks, as: :feedbackable
  has_and_belongs_to_many :accommodations
  has_and_belongs_to_many :eligibilities
  has_and_belongs_to_many :purposes
  belongs_to :start_or_end_area, class_name: 'Region', foreign_key: :start_or_end_area_id, dependent: :destroy
  belongs_to :trip_within_area, class_name: 'Region', foreign_key: :trip_within_area_id, dependent: :destroy

  ### VALIDATIONS & CALLBACKS ###
  validates_presence_of :name, :type
  validates_with FareValidator # For validating fare_structure and fare_details
  validates_comment_uniqueness_by_locale # From Commentable--requires only one comment per locale

  ##########
  # SCOPES #
  ##########

  ## Default Scope ##
  # where.not(archived: true) # set in Archivable module

  ## Primary Scopes ##
  scope :available_for, -> (trip) do
    available_for_time_and_geography(trip)
    .available_for_purpose_and_user(trip)
  end

  scope :available_for_time_and_geography, -> (trip) do 
    available_by_time_for(trip) #Filter First
    .available_by_geography_for(trip) #Filter Second
  end
    
  scope :available_for_purpose_and_user, -> (trip) do
    available_for_purpose_for(trip) #Filter Last
    .available_for_user(trip.user) #Filter Last
  end

  scope :transit_services, -> { where(type: "Transit") }
  scope :paratransit_services, -> { where(type: "Paratransit") }
  scope :taxi_services, -> { where(type: "Taxi") }
  scope :uber_services, -> { where(type: "Uber") }

  ## Secondary Scopes ##
  scope :available_for_purpose_for, -> (trip) { trip.purpose ? available_by_purpose(trip.purpose) : all }
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

  # find services available by a trips purpose
  scope :available_by_purpose, -> (purpose) do
    where(id: no_purposes | with_matching_purpose(purpose))
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
    :accommodates, :accepts_eligibility_of, :available_by_purpose_for,
    :available_by_schedule_for,
    :available_by_start_or_end_area_for, :available_by_trip_within_area_for

    
  ## Reporting Filter Scopes ##
  
  # Accommodation, Eligibility, and Purpose scopes filter by services that have one or more of the passed ids
  scope :with_accommodations, -> (accommodation_ids) do
    where(id: joins(:accommodations).where(accommodations: {id: accommodation_ids}).pluck(:id).uniq)
  end
  scope :with_eligibilities, -> (eligibility_ids) do
    where(id: joins(:eligibilities).where(eligibilities: {id: eligibility_ids}).pluck(:id).uniq)
  end
  scope :with_purposes, -> (purpose_ids) do
    where(id: joins(:purposes).where(purposes: {id: purpose_ids}).pluck(:id).uniq)
  end

  #################
  # CLASS METHODS #
  #################

  ### CONSTANTS ###
  SERVICE_TYPES = ['Transit', 'Paratransit', 'Taxi', 'Uber']



  ####################
  # INSTANCE METHODS #
  ####################
  
  def to_s
    name
  end
  
  def as_csv(options={})
    attributes.slice('name')
  end

  # Calculates fare for passed trip, based on service's fare_structure and fare_details
  def fare_for(trip, options={})
    if fare_structure == "zone"
      options[:origin_zone] = origin_zone_code(trip)
      options[:destination_zone] = destination_zone_code(trip)
    end
    FareCalculator.new(fare_structure, fare_details, trip, options).calculate
  end

  # OVERWRITE
  # Builds geographic associations.
  def build_geographies
    nil
  end

  # Silently filters out schedule params that don't meet criteria. Used in accepts_nested_attributes_for.
  def reject_schedule?(attrs)
    attrs['day'].blank? || attrs['start_time'].blank? || attrs['end_time'].blank?
  end

  # Returns a full logo url. By default, sends thumbnail version.
  def full_logo_url(version=:thumb)
    logo_version = version.nil? ? logo : logo.send(version)
    ActionController::Base.helpers.asset_path(logo_version.url.to_s)
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
    joins(:eligibilities).where(eligibilities: {code: user.confirmed_eligibilities.pluck(:code)}).pluck(:id)
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

  # Returns IDs of Services with no purposes set
  def self.no_purposes
    includes(:purposes).where(purposes: {id: nil}).pluck(:id)
  end

  # Returns IDs of Services with a schedule that includes the trip time
  def self.with_matching_schedule(trip)
    joins(:schedules).where(schedules: {
      day: trip.wday,
      start_time: 0..trip.secs,
      end_time: trip.secs..DAY_LENGTH
    }).pluck(:id)
  end

  # Returns IDs of Services with a purpose that includes the trip's purpose
  def self.with_matching_purpose(purpose)
    joins(:purposes).where(purposes: {code: purpose.code}) #Surely we can do this without comparing codes
  end

  # Returns IDs of Services with no region of given association type
  def self.no_region(region_type)
    includes(region_type).where(regions: { id: nil }).pluck(:id)
  end

  # Returns IDs of Services with a start_or_end_area that is EMPTY or containing trip origin OR destination
  def self.with_containing_start_or_end_area(trip)
    joins(:start_or_end_area).empty_region(:start_or_end_area)
    .or(joins(:start_or_end_area).region_contains(trip.origin.geom))
    .or(joins(:start_or_end_area).region_contains(trip.destination.geom))
    .pluck(:id)
  end

  # Returns IDs of Services with a trip_within_area that is EMPTY or containing trip origin AND destination
  def self.with_containing_trip_within_area(trip)
    joins(:trip_within_area)
    .region_contains(trip.origin.geom)
    .region_contains(trip.destination.geom)
    .or(joins(:trip_within_area).empty_region(:trip_within_area))
    .pluck(:id)
  end

  # Helper scope constructs a contains query based on region association name and a geometry
  scope :region_contains, -> (geom) do
    where("ST_Contains(regions.geom, ?)", geom.to_s)
  end

  # Helper scope constructs a query for empty regions
  scope :empty_region, -> (region="") do
    where("ST_IsEmpty(regions.geom)")
  end

end
