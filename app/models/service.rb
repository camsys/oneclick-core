class Service < ApplicationRecord

  ### INCLUDES & CONFIGURATION ###
  include Archivable # SETS DEFAULT SCOPE TO where.not(archived: true)
  include BookingHelpers::ServiceHelpers
  include Contactable
  include Describable # has translated descriptions for each available locale
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
  has_many :schedules, dependent: :destroy do
    # Builds a consolidated schedule, destroys the old ones, and saves the new
    def consolidate
      old_schedules = for_display.pluck(:id)
      where(id: old_schedules).destroy_all if build_consolidated.all?(&:save)
    end
  end

  has_one :service_oversight_agency, dependent: :destroy
  # has_many :feedbacks, as: :feedbackable
  has_many :travel_pattern_services, dependent: :destroy
  has_many :travel_patterns, through: :travel_pattern_services

  # Only add this association after the db is loaded so we can check config
  # Changes to this config will require a serer restart... not ideal, maybe move it into a custom class method?
  if ActiveRecord::Base.connection.table_exists?(:configs) && Config.dashboard_mode == "travel_patterns"
    has_many :purposes, -> { distinct }, through: :travel_patterns
  else
    has_and_belongs_to_many :purposes
  end

  has_and_belongs_to_many :accommodations, -> { distinct }
  has_and_belongs_to_many :eligibilities, -> { distinct }
  belongs_to :agency
  belongs_to :start_area, class_name: 'Region', foreign_key: :start_area_id, dependent: :destroy
  belongs_to :end_area, class_name: 'Region', foreign_key: :end_area_id, dependent: :destroy
  belongs_to :start_or_end_area, class_name: 'Region', foreign_key: :start_or_end_area_id, dependent: :destroy
  belongs_to :trip_within_area, class_name: 'Region', foreign_key: :trip_within_area_id, dependent: :destroy

  accepts_nested_attributes_for :travel_pattern_services, allow_destroy: true, reject_if: :all_blank

  ### VALIDATIONS & CALLBACKS ###
  validates_presence_of :name, :type, :agency, :max_age, :min_age
  validates_uniqueness_of :gtfs_agency_id, conditions: -> { where.not(archived: true, gtfs_agency_id: nil) }
  validates :max_age, :min_age, :eligible_max_age, :eligible_min_age, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates_with FareValidator # For validating fare_structure and fare_details
  contact_fields phone: :phone, email: :email, url: :url
  validate :valid_booking_profile
  after_save :consolidate_schedules # Combine overlapping schedules

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

  scope :no_agency, -> do
    where(agency_id: nil)
  end

  scope :no_oversight_agency, -> do
    left_joins(:service_oversight_agency).where('service_oversight_agencies.oversight_agency_id is null')
  end

  # Find Services with no Oversight Agency and no Transportation Agency
  scope :no_agencies_assigned, -> do
    left_joins(:service_oversight_agency).where('service_oversight_agencies.oversight_agency_id is null and services.agency_id is null')
  end

  scope :for_purpose, ->(purpose_id) {
    joins(:purposes).where(purposes: {id: purpose_id})
  }

  scope :with_any_oversight_agency, -> do
    joins(:service_oversight_agency).where('service_oversight_agencies.oversight_agency_id is not null')
  end

  # pass in the whole agency record
  scope :with_oversight_agency, -> (agency) do
    joins(:service_oversight_agency).where('service_oversight_agencies.oversight_agency_id': agency.id)
  end

  # This is a hack, we should change booking_details from a serialized string to an hstore to do proper searches
  scope :with_home_county, -> (county) do
    where('booking_details ~* ?', ".*home_counties:.*#{county}[ ]*(,|\n|\z).*")
  end

  # Filter by age
  # These are filters, that make people ineligible.
  scope :by_min_age, -> (age) { where("min_age < ?", age+1) }
  scope :by_max_age, -> (age) { where("max_age > ?", age-1) }

  # These are filters, that make people eligible
  scope :by_eligible_min_age, -> (age) { where("eligible_min_age < ?", age+1) }
  scope :by_eligible_max_age, -> (age) { where("eligible_max_age > ?", age-1) }
  
  AVAILABILITY_FILTERS = [
    :schedule, :geography, :eligibility, :accommodation, :purpose
  ]

  TAXI_SERVICES = %w[ Taxi Uber Lyft ]

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
  scope :lyft_services, -> { where(type: "Lyft") }

  ## Secondary Availability Scopes ##
  
  # Allowing the schedules' id to be nil includes services with no schedules set
  scope :available_by_schedule_for, -> (trip) do
    where(schedules: {id: nil})
      .or(where(schedules: {
        day: trip.wday,
        start_time: 0..trip.secs,
        end_time: trip.secs..DAY_LENGTH
      }))
      .left_joins(:schedules)
      .distinct
  end
  
  scope :available_by_geography_for, -> (trip) do
    available_by_start_area_for(trip)
      .available_by_end_area_for(trip)
      .available_by_start_or_end_area_for(trip)
      .available_by_trip_within_area_for(trip)
  end
  
  # Allowing the purposes' id to be nil includes services with no purposes selected
  scope :available_by_purpose_for, -> (trip) do
    Rails.logger.info "Applying purpose filter for trip with purpose_id: #{trip.purpose_id}"
    if trip.purpose_id.nil?
      Rails.logger.info "No purpose_id found, returning all services."
      self.all
    else
      filtered = where(purposes: { id: [nil, trip.purpose_id] }).left_joins(:purposes).distinct
      Rails.logger.info "Services found after purpose filter: #{filtered.pluck(:id)}"
      filtered
    end
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
  
  # Either no eligibilities are set, or the user meets an eligibility requirement
  scope :accepts_eligibility_of, -> (user) do
    where(eligibilities: { 
      id: [nil, *user.confirmed_user_eligibilities.pluck(:eligibility_id)] 
    }).left_joins(:eligibilities)
      .distinct
  end

  # Builds instance methods for determining if record falls within given scope
  build_instance_scopes :available_for, 
      :available_by_schedule_for,
      :available_by_geography_for,
      :available_by_purpose_for,
      :available_by_accommodation_for,
      :available_by_eligibility_for,
      :accommodates,
      :accepts_eligibility_of
    
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
  SERVICE_TYPES = ['Transit', 'Paratransit', 'Taxi', 'Uber', 'Lyft']



  ####################
  # INSTANCE METHODS #
  ####################

  def ada_funding_source_names
    booking_detail_to_array(:ada_funding_sources)
  end

  def banned_purpose_names
    booking_detail_to_array(:banned_purposes)
  end

  def banned_customer_ids
    booking_detail_to_array(:banned_users)
  end

  def home_county_names
    booking_detail_to_array(:home_counties).map { |county_name| 
      county_name.downcase.capitalize
    }
  end

  def preferred_sponsor_names
    booking_detail_to_array(:preferred_sponsors)
  end

  def preferred_funding_source_names
    booking_detail_to_array(:preferred_funding_sources)
  end
  
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

    if fare_structure == "use_booking_service"
      options[:service] = self
    end

    FareCalculator.new(fare_structure, fare_details, trip, options).calculate
  end

  # OVERWRITE
  # Builds geographic associations.
  def build_geographies
    nil
  end

  # If a Service is using a travel_pattern, then they've set a schedule for that pattern.
  # Their operating hours are the sum of all those schedules. 
  # We should look at replacing this code later.
  # - Drew 01/26/2022
  def business_days
    # Preloading all the travel_patterns and their schedules to avoid n+1 queries
    travel_patterns_with_schedules = self.travel_patterns.includes(
      travel_pattern_service_schedules: {
        service_schedule: [:service_schedule_type, :service_sub_schedules]
      }
    )
  
    # Get the travel_pattern's calendar, get rid of any dates without operating hours,
    # then add all remaining days into a set.
    travel_pattern_dates = travel_patterns_with_schedules.map { |travel_pattern|
      travel_pattern.to_calendar(localtime.to_date).select { |date, time_ranges|
        time_ranges.any? { |range| range[:start_time]&.>(0) && range[:end_time]&.>(0) }
      }.keys
    }
  
    Set.new(travel_pattern_dates.flatten)
  end  

  # Our client is in Pennsylvania. Currently servers are in the same time zone, but I don't want
  # to break things if our servers move. If we gain other clients, we should add a timezone field.
  def localtime
    service_time_zone = "-05:00"
    Time.now.localtime(service_time_zone)
  end

  # Silently filters out schedule params that don't meet criteria. Used in accepts_nested_attributes_for.
  def reject_schedule?(attrs)
    attrs['day'].blank? || attrs['start_time'].blank? || attrs['end_time'].blank?
  end
  
  # formatted_phone method defined in the Contactable module.
  # Returns a prettily formatted phone number string, like ""(555) 555-5555"
  # def formatted_phone
  # end

  ###################
  private # PRIVATE #
  ###################

  # Consolidates schedules automatically after save
  def consolidate_schedules
    schedules.consolidate
  end

  def booking_detail_to_array(key)
    booking_details.fetch(key, '')
                    .split(',')
                    .map(&:strip)
  end


  ### SCOPE HELPER METHODS ###

  # available_by_geography_for scopes
  scope :available_by_start_area_for, -> (trip) do
    # no start_area contains origin
    where( id: no_region(:start_area) | with_containing_start_area(trip) )
  end
  scope :available_by_end_area_for, -> (trip) do
    # no end_area contains destination
    where( id: no_region(:end_area) | with_containing_end_area(trip) )
  end
  scope :available_by_start_or_end_area_for, -> (trip) do
    # no start_or_end_area, or start_or_end_area contains origin OR destination
    where( id: no_region(:start_or_end_area) | with_containing_start_or_end_area(trip) )
  end
  scope :available_by_trip_within_area_for, -> (trip) do
    # no trip_within_area, or trip_within_area contains origin OR destination
    where( id: no_region(:trip_within_area) | with_containing_trip_within_area(trip) )
  end

  # Returns all services that provide a given accommodation
  scope :accommodates_by_code, -> (code) { joins(:accommodations).where(accommodations: {code: code}) }
  scope :accommodates_accommodation, -> (accommodation) { joins(:accommodations).where(accommodations: {id: accommodation.id})}

  # Returns IDs of Services that accommodate all of a user's needs
  def self.accommodates_all_needs(user)
    user.accommodations.map {|acc| Service.accommodates_accommodation(acc).pluck(:id)}.reduce(&:&)
  end

  # Returns IDs of Services with no region of given association type
  def self.no_region(region_type)
    includes(region_type).where(regions: { id: nil }).pluck(:id)
  end

  # Returns IDs of Services with a start_area that is EMPTY or containing trip origin
  def self.with_containing_start_area(trip)
    joins(:start_area).empty_region(:start_area)
    .or(joins(:start_area).region_contains(trip.origin.geom))
    .pluck(:id)
  end

  # Returns IDs of Services with a end_area that is EMPTY or containing trip destination
  def self.with_containing_end_area(trip)
    joins(:end_area).empty_region(:end_area)
    .or(joins(:end_area).region_contains(trip.destination.geom))
    .pluck(:id)
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
    where("ST_Within(regions.geom, ?)", geom)
  end

  # Helper scope constructs a query for empty regions
  scope :empty_region, -> (region="") do
    where("ST_IsEmpty(regions.geom)")
  end

  def self.service_types
    Config.dashboard_mode.to_sym == :travel_patterns ? ['Paratransit'] : ['Transit', 'Paratransit', 'Taxi', 'Uber', 'Lyft']
  end

end
