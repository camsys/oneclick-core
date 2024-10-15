class TravelPattern < ApplicationRecord
  scope :ordered, -> {joins(:agency).order("agencies.name, travel_patterns.name")}
  scope :for_superuser, -> {all}
  scope :for_oversight_user, -> (user) {where(agency: user.current_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.current_agency.id]))}
  scope :for_current_transport_user, -> (user) {where(agency: user.current_agency)}
  scope :for_transport_user, -> (user) {where(agency: user.staff_agency)}

  ## 
  # This scope returns only Travel Patterns related to the +Agency+ provided.
  # 
  # @param [Agency] agency The +Agency+ used to select Travel Patterns.
  scope :with_agency, -> (agency) do
    raise TypeError.new("#{agency.class} can't be coerced into Agency") unless agency.is_a?(Agency)
    TravelPattern.where(agency_id: agency.id)
  end

  ## 
  # This scope returns only Travel Patterns related to the +Service+ provided.
  # 
  # @param [Service] service The +Service+ used to select Travel Patterns.
  scope :with_service, -> (service) do
    raise TypeError.new("#{service.class} can't be coerced into Service") unless service.is_a?(Service)
    joins(:travel_pattern_services).where(travel_pattern_services: {service_id: service.id}).distinct
  end

  
  scope :with_origin_and_destination, ->(origin, destination) {
    raise ArgumentError.new("origin must contain :lat and :lng") unless origin[:lat].present? && origin[:lng].present?
    raise ArgumentError.new("destination must contain :lat and :lng") unless destination[:lat].present? && destination[:lng].present?
  
    queried_origin = OdZone.joins(:region).where(region: Region.containing_point(origin[:lng], origin[:lat])).pluck(:id)
    queried_destination = OdZone.joins(:region).where(region: Region.containing_point(destination[:lng], destination[:lat])).pluck(:id)
  
    Rails.logger.info "Queried Origin Zone IDs: #{queried_origin}"
    Rails.logger.info "Queried Destination Zone IDs: #{queried_destination}"
  
    Rails.logger.info "Querying for patterns with origin and destination"
  
    patterns = where(
      (origin_zone_id: queried_origin, destination_zone_id: queried_destination)
      .or(
        { destination_zone_id: queried_origin, origin_zone_id: queried_destination, allow_reverse_sequence_trips: true }
      )
    )
  
    Rails.logger.info "Initial Patterns found: #{patterns.pluck(:id)}"
  
    patterns.tap do |result|
      Rails.logger.info "Travel Patterns found for origin and destination: #{result.pluck(:id)}"
      result.each do |pattern|
        actual_origin_zone = pattern.origin_zone_id
        actual_destination_zone = pattern.destination_zone_id
  
        Rails.logger.info "Pattern ID: #{pattern.id}, Actual Origin Zone ID: #{actual_origin_zone}, Actual Destination Zone ID: #{actual_destination_zone}, Allow Reverse: #{pattern.allow_reverse_sequence_trips}"
      end
  
      valid_patterns = result.select do |pattern|
        actual_origin_zone = pattern.origin_zone_id
        actual_destination_zone = pattern.destination_zone_id
  
        Rails.logger.info "Evaluating Pattern ID: #{pattern.id}"
        Rails.logger.info "Queried Origin Zone IDs: #{queried_origin}, Queried Destination Zone IDs: #{queried_destination}"
        Rails.logger.info "Actual Origin Zone ID: #{actual_origin_zone}, Actual Destination Zone ID: #{actual_destination_zone}"
        
        # Determine the source of the match
        origin_match = queried_origin.include?(actual_origin_zone)
        Rails.logger.info "Origin match: #{origin_match}"
        destination_match = queried_destination.include?(actual_destination_zone)
        Rails.logger.info "Destination match: #{destination_match}"
        
        # Check if both origin and destination are the same zone and allowed
        if actual_origin_zone == actual_destination_zone && origin_match && destination_match
          Rails.logger.info "Allowing same-zone trip for pattern ID: #{pattern.id} where both origin and destination are #{actual_origin_zone}"
          true
        
        # Allow reverse trips when allowed and zones are different
        elsif destination_match && origin_match && actual_origin_zone != actual_destination_zone && pattern.allow_reverse_sequence_trips
          Rails.logger.info "Allowing reverse trip for pattern ID: #{pattern.id} from destination to origin"
          true
        
        # Allow regular trips from origin to destination only if destination is in the queried zones
        elsif origin_match && queried_destination.include?(actual_destination_zone)
          Rails.logger.info "Allowing regular trip for pattern ID: #{pattern.id} from origin to destination"
          true
        
        # Allow reverse trips from destination to origin only if origin is in the queried zones and reverse trips are allowed
        elsif destination_match && queried_origin.include?(actual_origin_zone) && pattern.allow_reverse_sequence_trips
          Rails.logger.info "Allowing reverse trip for pattern ID: #{pattern.id} from destination to origin"
          true
  
        elsif pattern.allow_reverse_sequence_trips && queried_origin.include?(actual_destination_zone) && queried_destination.include?(actual_origin_zone)
          Rails.logger.info "Allowing reverse trip for pattern ID: #{pattern.id} from destination to origin"
          true
        
        # Disallow invalid trips where origin and destination do not match correctly
        else
          Rails.logger.info "Skipping pattern ID: #{pattern.id} due to invalid origin-destination combination"
          false
        end
      end
  
      Rails.logger.info "Final valid patterns: #{valid_patterns.map(&:id)}"
      if valid_patterns.empty?
        Rails.logger.info "No valid travel patterns found for origin and destination"
        raise ActiveRecord::RecordNotFound, "No valid travel patterns found for origin and destination"
      end
  
      valid_patterns
    end
  }
  


  ##
  # This scope returns only Travel Patterns where the provided +Purpose+ is included in the Travel
  # Pattern's list of associated purposes.
  # 
  # @param [Purpose] purpose The +Purpose+ used to select Travel Patterns.
  scope :with_purpose, -> (purpose) do
    raise TypeError.new("#{purpose.class} can't be coerced into Purpose") unless purpose.is_a?(Purpose)
    joins(:travel_pattern_purposes).where(travel_pattern_purposes: {purpose_id: purpose.id}).distinct
  end

  ##
  # This scope returns only Travel Patterns where the provided +purpose_id+ is included in the
  # Travel Pattern's list of associated purposes.
  # 
  # @param [Number] purpose_id The +Purpose+ used to select Travel Patterns.
  scope :with_purpose_id, -> (purpose_id) do
    raise TypeError.new("#{purpose_id.class} can't be coerced into Integer") unless purpose_id.is_a?(Integer)
    joins(:travel_pattern_purposes).where(travel_pattern_purposes: {purpose_id: purpose_id}).distinct
  end

  ##
  # This scope returns only Travel Patterns where at least one provided +FundingSource+ is included
  # in the Travel Pattern's list of associated funding sources.
  # 
  # @param funding_sources [ActiveRecord::Relation<FundingSource>] The +FundingSource+s used to
  # select Travel Patterns.
  scope :with_funding_sources, -> (funding_sources) do
    unless funding_sources.is_a?(ActiveRecord::Relation) && funding_sources.model == FundingSource
      raise TypeError.new("#{funding_sources.class} can't be coerced into ActiveRecord::Relation<FundingSource>")
    end

    joins(:travel_pattern_funding_sources).where(travel_pattern_funding_sources: {funding_source: funding_sources}).distinct
  end

  ##
  # This scope returns only Travel Patterns where at least one provided +funding_source_id+ is
  # included in the Travel Pattern's list of associated funding sources.
  # 
  # @param funding_source_ids [Array<Number>] The +Id+s of +FundingSources+s.
  scope :with_funding_source_ids, -> (funding_source_ids) do
    unless funding_source_ids.is_a?(Array) && funding_source_ids.all? { |fsi| fsi.class == Integer }
      raise TypeError.new("#{funding_source_ids.class} can't be coerced into Array<Integer>")
    end

    joins(:travel_pattern_funding_sources).where(travel_pattern_funding_sources: {funding_source_id: funding_source_ids}).distinct
  end

  ##
  # This scope returns only Travel Patterns where the provided +date+ occurs within both the Travel
  # Pattern's accociated Service Schedules and Booking Window.
  # 
  # @param [Date] date The date to use.
  scope :with_date, -> (date) do
    raise TypeError.new("#{date.class} can't be coerced into Date") unless date.is_a?(Date) 

    joins(:travel_pattern_service_schedules, :booking_window)
      .where(travel_pattern_service_schedules: {service_schedule: ServiceSchedule.for_date(date)})
      .where(booking_window: BookingWindow.for_date(date)).distinct
  end

  belongs_to :agency
  belongs_to :booking_window
  belongs_to :origin_zone, class_name: 'OdZone'
  belongs_to :destination_zone, class_name: 'OdZone'

  has_many :travel_pattern_services, dependent: :destroy
  has_many :services, through: :travel_pattern_services, dependent: :restrict_with_error
  has_many :travel_pattern_service_schedules, dependent: :destroy
  has_many :service_schedules, through: :travel_pattern_service_schedules
  has_many :travel_pattern_purposes, dependent: :destroy
  has_many :purposes, through: :travel_pattern_purposes
  has_many :travel_pattern_funding_sources, dependent: :destroy
  has_many :funding_sources, through: :travel_pattern_funding_sources

  accepts_nested_attributes_for :travel_pattern_service_schedules, allow_destroy: true, reject_if: proc { |attr| attr[:service_schedule_id].blank? }
  accepts_nested_attributes_for :travel_pattern_purposes, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :travel_pattern_funding_sources, allow_destroy: true, reject_if: :all_blank

  validates :name, uniqueness: {scope: :agency_id}
  # TODO: verify whether the presence of a service schedule is good enough, or if it has to be a specific kind of schedule.
  validates_presence_of :name, :booking_window, :agency, :origin_zone, :destination_zone, :travel_pattern_funding_sources, :travel_pattern_purposes, :travel_pattern_service_schedules

  def to_api_response(start_date, end_date, valid_from = nil, valid_until = nil)
    travel_pattern_opts = { 
      only: [:id, :agency_id, :name, :description]
    }
    valid_from = Date.strptime(valid_from, '%Y-%m-%d') if valid_from.is_a?(String)
    valid_until = Date.strptime(valid_until, '%Y-%m-%d') if valid_until.is_a?(String)    
    start_date = [start_date, valid_from].compact.max if valid_from
    end_date = [end_date, valid_until].compact.min if valid_until
  
    calendar_data = self.to_calendar(start_date, end_date, valid_from, valid_until)
  
    # Adjust the calendar data for serialization
    adjusted_calendar_data = calendar_data.transform_values do |time_ranges|
      # Transform each time range in the array into a serializable format, if necessary
      time_ranges.map { |range| { start_time: range[:start_time], end_time: range[:end_time] } }
    end
  
    self.as_json(travel_pattern_opts).merge({
      "to_calendar" => adjusted_calendar_data
    })
  end  

  def self.for_user(user)
    if user.superuser?
      for_superuser.ordered
    elsif user.currently_oversight?
      for_oversight_user(user).ordered
    elsif user.currently_transportation?
      for_current_transport_user(user).order("name desc")
    elsif user.transportation_user?
      for_transport_user(user).order("name desc")
    else
      nil
    end
  end

  def schedules_by_type
    pre_loaded = self.association(:travel_pattern_service_schedules).loaded?

    # Prepping the return value
    schedules_by_type = {
      weekly_schedules: [],
      extra_service_schedules: [],
      reduced_service_schedules: [],
    }

    # Get all associated schedules (in reverse alphabetical order)
    service_schedules = pre_loaded ? 
                          self.travel_pattern_service_schedules.to_a :
                          self.travel_pattern_service_schedules
                            .eager_load(service_schedule: [:service_schedule_type, :service_sub_schedules])
                            .joins(:service_schedule)
                            .merge(ServiceSchedule.order(name: :desc))
                            .to_a
    
    # Sort Schedules by type
    # This also reverses the order, so now they're sorted alphabetically
    while service_schedules.length > 0 do
      schedule = service_schedules.pop

      schedules_by_type[:weekly_schedules].push(schedule) if schedule.is_a_weekly_schedule?
      schedules_by_type[:extra_service_schedules].push(schedule) if schedule.is_an_extra_service_schedule?
      schedules_by_type[:reduced_service_schedules].push(schedule) if schedule.is_a_reduced_service_schedule?
    end

    return schedules_by_type
  end

  ##
  # This method aggregates all of a +TravelPattern+'s service schedules and aggregates them to
  # produce a hash showing the valid times for this pattern the next 60 days. This does not
  # take into account constraints from the Booking Window. For that you should pass in the
  # +start_date+ and +calendar_length+ with the relevant information.
  # 
  # @param [Integer] start_date Optional. The first day that the calendar wil calculate the
  #   +start_time+ and +end_time+ for. (Use the timezone of the +Service+)
  # @param [Integer] end_date Optional. The last day that the calendar will calculate the
  #   +start_time+ and +end_time+ for. (Use the timezone of the +Service+)
  # 
  # Default options are:
  #   :calendar_length => +start_date+ + 59.days
  # 
  # @return [Hash] The structure is {"%Y-%m-%d" => { start_time: +Integer+, end_time: +Integer+ }}
  def to_calendar(start_date, end_date = start_date + 59.days, valid_from = nil, valid_until = nil)
    travel_pattern_service_schedules = schedules_by_type
  
    weekly_schedules = travel_pattern_service_schedules[:weekly_schedules].map(&:service_schedule)
    extra_service_schedules = travel_pattern_service_schedules[:extra_service_schedules].map(&:service_schedule)
    reduced_service_schedules = travel_pattern_service_schedules[:reduced_service_schedules].map(&:service_schedule)
  
    calendar = {}
    date = start_date
  
    while date <= end_date
      date_string = date.strftime('%Y-%m-%d')
      calendar[date_string] = []
      
      has_holiday = false
  
      # Check reduced service schedules for holidays (nil start and end times)
      reduced_service_schedules.each do |service_schedule|
        next unless (service_schedule.start_date.nil? || service_schedule.start_date <= date) && 
                    (service_schedule.end_date.nil? || service_schedule.end_date >= date)
  
        service_schedule.service_sub_schedules.each do |sub_schedule|
          if sub_schedule.calendar_date == date && sub_schedule.start_time.nil? && sub_schedule.end_time.nil?
            # Mark as holiday; do not add any time slots for this day
            has_holiday = true
            break
          end
        end
  
        break if has_holiday # Exit early if a holiday is found
      end
  
      # Proceed with adding time slots only if no holiday was found
      unless has_holiday
        sub_schedules = (weekly_schedules + extra_service_schedules).flat_map do |service_schedule|
          next unless (service_schedule.start_date.nil? || service_schedule.start_date <= date) &&
                      (service_schedule.end_date.nil? || service_schedule.end_date >= date)
  
          service_schedule.service_sub_schedules.select do |sub_schedule|
            (sub_schedule.day == date.wday || sub_schedule.calendar_date == date) &&
            !(sub_schedule.start_time.nil? && sub_schedule.end_time.nil?) # Exclude nil times
          end
        end.compact
  
        # Map to start_time and end_time, excluding nil values explicitly
        sub_schedules.each do |ss|
          calendar[date_string] << { start_time: ss.start_time, end_time: ss.end_time } unless ss.start_time.nil? || ss.end_time.nil?
        end
      end
  
      # Move to the next day
      date += 1.day
    end
  
    calendar
  end
  
  
  
  
  
  

  # Class Methods

  ##
  # A method for quickly filtering through Travel Patterns based on a param hash passed in as an
  # arguemnt. All params are optional. Any params not included in the hash will not be used to
  # filter with.
  #
  # @param [Hash] query_params The params hash used to select Travel Patterns.
  # @option query_params [Agency] :agency The *Agency* that the Travel Patterns should belong to.
  # @option query_params [Service] :service A *Service* that the Travel Patterns should be associated with.
  # @option query_params [Hash] :origin A hash representing a starting point for a potential Trip. 
  # @option origin [Number] :lat
  # @option origin [Number] :lng
  # @option query_params [Hash] :destination A hash representing an ending point for a potential Trip. 
  # @option destination [Number] :lat
  # @option destination [Number] :lng
  # @option query_params [Purpose] :purpose A *Purpose* that the Travel Pattern should be associated with.
  # @option query_params [FundingSource] :funding_source A *FundingSource* that the Travel Pattern should be associated with.
  # @option query_params [Date] :date A *Date* that the Travel Pattern should be able to book a trip for.
  # @option query_params [String, Integer] :start_time The starting time of a potential trip represented  as number of seconds since midnight.
  # @option query_params [String, Integer] :end_time The ending time of a potential trip represented  as number of seconds since midnight.
  def self.available_for(query_params)
    filters = [
      :agency, 
      :service, 
      :purpose, :purpose_id, 
      :funding_sources, :funding_source_ids, 
      :date
    ]
    query = self.all

    Rails.logger.info "Initial query: #{query.to_sql}"

    # First filter by all provided params except origin and destination
    filters.each do |filter|
      method_name = ("with_" + filter.to_s).to_sym
      param = query_params[filter]

      if param
        Rails.logger.info "Applying filter: #{filter} with param: #{param}"
        query = query.send(method_name, param)
        Rails.logger.info "Query after applying #{filter}: #{query.to_sql}"
      end
    end

    # Handle origin and destination together
    if query_params[:origin] && query_params[:destination]
      Rails.logger.info "Applying with_origin_and_destination with origin: #{query_params[:origin]} and destination: #{query_params[:destination]}"
      query = query.with_origin_and_destination(query_params[:origin], query_params[:destination])
    else
      if query_params[:origin]
        Rails.logger.info "Applying with_origin with origin: #{query_params[:origin]}"
        query = query.with_origin(query_params[:origin])
      end
      if query_params[:destination]
        Rails.logger.info "Applying with_destination with destination: #{query_params[:destination]}"
        query = query.with_destination(query_params[:destination])
      end
    end

    Rails.logger.info "Query before filtering by time: #{query.to_sql}"

    # Filter by time if start_time and end_time are provided
    travel_patterns = self.filter_by_time(query.distinct, query_params[:start_time], query_params[:end_time])

    Rails.logger.info "Final travel patterns: #{travel_patterns.map(&:id)}"

    travel_patterns
  end

  def self.to_api_response(travel_patterns, service, valid_from = nil, valid_until = nil)
    business_days = service.business_days

    # Filter out any patterns with no bookable dates. This can happen prior to selecting a date and time
    # if a travel pattern has only calendar date schedules and the dates are outside of the booking window.
    travel_patterns = [travel_patterns].flatten
    travel_patterns.map { |travel_pattern|
      booking_window = travel_pattern.booking_window
      additional_notice = service.localtime.hour >= booking_window.minimum_notice_cutoff_hour
      date = service.localtime.to_date
      start_date = date
      end_date = date + 60.days

      days_notice = (business_days.include?(date.strftime('%Y-%m-%d')) && !additional_notice) ? 0 : -1
      while (days_notice < booking_window.minimum_days_notice && date < end_date) do
        date += 1.day
        days_notice += 1 if business_days.include?(date.strftime('%Y-%m-%d'))
      end

      start_date = date

      while (days_notice < booking_window.maximum_days_notice && date < end_date) do
        date += 1.day
        days_notice += 1 if business_days.include?(date.strftime('%Y-%m-%d'))
      end
      
      end_date = date

      travel_pattern.to_api_response(start_date, end_date, valid_from, valid_until)
    }
    .select { |travel_pattern|
      calendar_business_hours = travel_pattern["to_calendar"].values
      calendar_business_hours.any? do |time_ranges|
        time_ranges.any? { |range| (range[:start_time] || -1) >= 0 && (range[:end_time] || -1) >= 1 }
      end
    }
  end

  # This method should be the first time we call the database, before this we were only constructing the query
  def self.filter_by_time(travel_pattern_query, trip_start, trip_end)
    return travel_pattern_query unless trip_start
    trip_start = trip_start.to_i
    trip_end = (trip_end || trip_start).to_i

    Rails.logger.info("Filtering through Travel Patterns that have a Service Schedule running from: #{trip_start / 1.hour}:#{trip_start % 1.hour / 1.minute}, to: #{trip_end / 1.hour}:#{trip_end % 1.hour / 1.minute}")
    # Eager loading will ensure that all the previous filters will still apply to the nested relations
    travel_patterns = travel_pattern_query.eager_load(travel_pattern_service_schedules: { service_schedule: [:service_schedule_type, :service_sub_schedules] })
    Rails.logger.info("Travel Patterns before time filtering: #{travel_patterns.map(&:id)}")

    valid_patterns = travel_patterns.select do |travel_pattern|
      schedules = travel_pattern.schedules_by_type

      # If there are reduced schedules, then we don't need to check any other schedules
      if schedules[:reduced_service_schedules].present?
        Rails.logger.info("Travel Pattern ##{travel_pattern.id} has matching reduced service schedules")
        schedules = schedules[:reduced_service_schedules]
      else
        Rails.logger.info("Travel Pattern ##{travel_pattern.id} does not have matching calendar date schedules, checking other schedule types")
        schedules = schedules[:weekly_schedules] + schedules[:extra_service_schedules]
      end

      # Grab any valid schedules
      valid_schedule = schedules.any? do |travel_pattern_service_schedule|
        service_schedule = travel_pattern_service_schedule.service_schedule
        service_schedule.service_sub_schedules.any? do |sub_schedule|
          valid_start_time = sub_schedule.start_time <= trip_start
          valid_end_time = sub_schedule.end_time >= trip_end

          valid_start_time && valid_end_time
        end
      end

      Rails.logger.info("Travel Pattern ##{travel_pattern.id} valid schedule: #{valid_schedule}")
      valid_schedule
    end

    Rails.logger.info("Valid Travel Patterns after time filtering: #{valid_patterns.map(&:id)}")
    valid_patterns
  end

end