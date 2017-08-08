class Service < ApplicationRecord

  ### INCLUDES & CONFIGURATION ###
  include Archivable # SETS DEFAULT SCOPE TO where.not(archived: true)
  include BookingHelpers::ServiceHelpers
  include Commentable # has_many :comments
  include Contactable
  include FareHelper
  include FareHelper::ZoneFareable
  include Feedbackable
  include GeoKitchen
  include Logoable # mounts LogoUploader
  include Publishable
  include ScheduleHelper
  include ScopeHelper
  write_to_csv with: Admin::ServicesReportCSVWriter

  ### ATTRIBUTES & ASSOCIATIONS ###
  serialize :fare_details
  has_many :user_booking_profiles
  has_many :itineraries, dependent: :nullify
  has_many :schedules, dependent: :destroy
  has_many :feedbacks, as: :feedbackable
  has_and_belongs_to_many :accommodations
  has_and_belongs_to_many :eligibilities
  has_and_belongs_to_many :purposes
  belongs_to :agency
  belongs_to :start_or_end_area, class_name: 'Region', foreign_key: :start_or_end_area_id, dependent: :destroy
  belongs_to :trip_within_area, class_name: 'Region', foreign_key: :trip_within_area_id, dependent: :destroy

  ### VALIDATIONS & CALLBACKS ###
  validates_presence_of :name, :type
  validates_with FareValidator # For validating fare_structure and fare_details
  validates_comment_uniqueness_by_locale # From Commentable--requires only one comment per locale
  contact_fields phone: :phone, email: :email

  ##########
  # SCOPES #
  ##########
  
  # NOTE: Many of the scopes below are used for determining which services are
  # available for a given trip or user. They are ordered more or less by
  # level of abstraction, with general high-level scopes like "available_for"
  # calling more specific ones like "available_by_purpose_for"

  ## Default Scope ##
  # where.not(archived: true) # set in Archivable module

  scope :by_trip_type, -> (*trip_types) do
    where(type: trip_types.map { |tt| tt.to_s.classify })
  end
  
  AVAILABILITY_FILTERS = [
    :schedule, :geography, :eligibility, :accommodation, :purpose
  ]

  ### MASTER AVAILABILITY SCOPE ###
  # Returns all services available for the given trip.
  # Optional :only_by and :except_by params allow you to only filter
  # by select criteria (schedule, geography, eligibility, accommodation, purpose)
  def self.available_for(trip, opts={})
    only_filters = opts[:only_by] || AVAILABILITY_FILTERS
    except_filters = opts[:except_by] || []    
    filters = only_filters - except_filters
    
    # Setting logger level to 1 or less will show messages describing each
    # availability filter as it is applied. This will have a moderate impact 
    # on performance (call takes ~35% longer).
    logger.info { "*** FILTERING AVAILABLE SERVICES by #{filters} ***"}
    logger.info {"Available Services before Filtering: #{self.all.pluck(:id)}"}
    
    available_services = filters.reduce(self.all) do |scope, filter|
      filtered_scope = scope.available_by_filter_for(filter, trip)
      
      logger.info {"Available Services after Filtering on #{filter}: #{filtered_scope.pluck(:id)}"}
      
      filtered_scope
    end
    
    logger.info {"Available Services after Filtering: #{available_services.pluck(:id)}"}
    
    return available_services
  end
  
  def self.available_by_filter_for(filter, trip)
    case filter
    when :schedule
      return self.available_by_schedule_for(trip)
    when :geography
      return self.available_by_geography_for(trip)
    when :eligibility
      return self.available_by_eligibility_for(trip)
    when :accommodation
      return self.available_by_accommodation_for(trip)
    when :purpose
      return self.available_by_purpose_for(trip)
    else
      return self.all
    end
  end

  scope :transit_services, -> { where(type: "Transit") }
  scope :paratransit_services, -> { where(type: "Paratransit") }
  scope :taxi_services, -> { where(type: "Taxi") }
  scope :uber_services, -> { where(type: "Uber") }

  ## Secondary Availability Scopes ##
  
  scope :available_by_schedule_for, -> (trip) do
    # Either no schedules are set, or there is a schedule that includes the trip time
    where( id: no_schedules | with_matching_schedule(trip) )
  end
  
  scope :available_by_geography_for, -> (trip) do
    available_by_start_or_end_area_for(trip)
    .available_by_trip_within_area_for(trip)
  end
  
  scope :available_by_purpose_for, -> (trip) do
    trip.purpose ? available_by_purpose(trip.purpose) : all
  end
  
  scope :available_by_eligibility_for, -> (trip) do
    trip.user ? accepts_eligibility_of(trip.user) : all
  end
  
  scope :available_by_accommodation_for, -> (trip) do
    trip.user ? accommodates(trip.user) : all
  end
  
  # Includes service if either it accommodates all the user's needs, or the
  # user has no needs.
  scope :accommodates, -> (user) do
    if user.accommodations.empty?
      all
    else
      where(id: accommodates_all_needs(user))
    end
  end
  
  # Includes service if either it has no eligibility requirements, or the user
  # meets at least one of its eligibility requirements
  scope :accepts_eligibility_of, -> (user) do
    # Either no eligibilities are set, or the user meets an eligibility requirement
    where( id: no_eligibilities | with_met_eligibilities(user) )
  end

  # find services available by a trips purpose
  scope :available_by_purpose, -> (purpose) do
    where(id: no_purposes | with_matching_purpose(purpose))
  end

  # Builds instance methods for determining if record falls within given scope
  build_instance_scopes :available_for, 
      :available_by_schedule_for,
      :available_by_geography_for,
      :available_by_purpose_for,
      :available_by_accommodation_for,
      :available_by_eligibility_for,
      :accommodates,
      :accepts_eligibility_of,
      :available_by_purpose
    
  ## Other Scopes ##
  
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

  # Returns services that either have no umbrella agency, or already belong to the passed agency
  scope :available_to_agency, -> (agency) do
    where(transportation_agency: [nil, agency]).order(:name)
  end
  
  # Returns services that have another agency as their umbrella agency
  scope :unavailable_to_agency, -> (agency) do
    where.not(transportation_agency: agency).order(:name)
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

  ###################
  private # PRIVATE #
  ###################


  ### SCOPE HELPER METHODS ###

  # available_by_geography_for scopes
  scope :available_by_start_or_end_area_for, -> (trip) do
    # no start_or_end_area, or start_or_end_area contains origin OR destination
    where( id: no_region(:start_or_end_area) | with_containing_start_or_end_area(trip) )
  end
  scope :available_by_trip_within_area_for, -> (trip) do
    # no trip_within_area, or trip_within_area contains origin OR destination
    where( id: no_region(:trip_within_area) | with_containing_trip_within_area(trip) )
  end

  # Returns IDs of Services with no eligibility requirements
  def self.no_eligibilities
    includes(:eligibilities).where(eligibilities: {id: nil}).pluck(:id)
  end

  # Returns IDs of Services with at least one eligibility requirement met by user
  def self.with_met_eligibilities(user)
    joins(:eligibilities).where(eligibilities: {id: user.confirmed_eligibilities.pluck(:id)}).pluck(:id)
  end

  # Returns all services that provide a given accommodation
  scope :accommodates_by_code, -> (code) { joins(:accommodations).where(accommodations: {code: code}) }
  scope :accommodates_accommodation, -> (accommodation) { joins(:accommodations).where(accommodations: {id: accommodation.id})}

  # Returns IDs of Services that accommodate all of a user's needs
  def self.accommodates_all_needs(user)
    user.accommodations.map {|acc| Service.accommodates_accommodation(acc).pluck(:id)}.reduce(&:&)
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
    joins(:purposes).where(purposes: {id: purpose.id}) #Surely we can do this without comparing codes
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
    where("ST_Contains(regions.geom, ?)", geom)
  end

  # Helper scope constructs a query for empty regions
  scope :empty_region, -> (region="") do
    where("ST_IsEmpty(regions.geom)")
  end

end
