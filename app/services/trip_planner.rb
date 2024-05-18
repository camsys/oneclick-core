###
# TRIP PLANNER is in charge of handling the business logic around building
# itineraries for a trip, and pulling in information from various 3rd-party
# APIs.

class TripPlanner

  # Constant list of trip types that can be planned.
  TRIP_TYPES = Trip::TRIP_TYPES
  attr_reader :options, :router, :errors, 
              :trip_types, :available_services, :http_request_bundler,
              :relevant_purposes, :relevant_accommodations, :relevant_eligibilities,
              :only_filters, :except_filters, :filters
  attr_accessor :trip, :master_service_scope

  # Initialize with a Trip object, and an options hash
  def initialize(trip, options={})
    @trip = trip
    @options = options
    @trip_types = (options[:trip_types] || TRIP_TYPES) & TRIP_TYPES
    if Config.open_trip_planner_version != 'v1' && (@trip_types.include?(:car) && @trip_types.include?(:transit))
      @trip_types.push(:car_park)
    end    
    @purpose = Purpose.find_by(id: @options[:purpose_id])

    @errors = []
    @paratransit_drive_time_multiplier = 2.5
    @master_service_scope = options[:available_services] || Service.all
    @http_request_bundler = options[:http_request_bundler] || HTTPRequestBundler.new
    @relevant_eligibilities = @relevant_purposes = @relevant_accommodations = []

    @only_filters = (options[:only_filters] || Service::AVAILABILITY_FILTERS) & Service::AVAILABILITY_FILTERS
    @except_filters = options[:except_filters] || []
    @filters = @only_filters - @except_filters

    @router = options[:router]
    @taxi_ambassador = options[:taxi_ambassador]
    @uber_ambassador = options[:uber_ambassador]
    @lyft_ambassador = options[:lyft_ambassador]
  end

  def plan
    set_available_services
    prepare_ambassadors
    build_all_itineraries
    filter_itineraries
    check_no_valid_services
    @trip.save
  end

  def prepare_ambassadors
    @router ||= OTPAmbassador.new(@trip, @trip_types, @http_request_bundler, @available_services[:transit])
    @taxi_ambassador ||= TFFAmbassador.new(@trip, @http_request_bundler, services: @available_services[:taxi])
    @uber_ambassador ||= UberAmbassador.new(@trip, @http_request_bundler)
    @lyft_ambassador ||= LyftAmbassador.new(@trip, @http_request_bundler)
  end

  def set_available_services
    @available_services = @master_service_scope.published
    @available_services = @available_services.by_trip_type(*@trip_types)
    if @trip.user && @trip.user.age
      @available_services = @available_services.by_max_age(@trip.user.age).by_min_age(@trip.user.age)
    end
    @available_services = @available_services.available_for(@trip, only_by: (@filters - [:purpose, :eligibility, :accommodation]))
    @relevant_purposes = (@available_services.collect { |service| service.purposes }).flatten.uniq
    @relevant_eligibilities = (@available_services.collect { |service| service.eligibilities }).flatten.uniq.sort_by{ |elig| elig.rank }
    @relevant_accommodations = Accommodation.all.ordered_by_rank
    @available_services = @available_services.available_for(@trip, only_by: (@filters & [:purpose, :eligibility, :accommodation]))
    @available_services = available_services_hash(@available_services)
  end

  def available_services_hash(services)
    Service::SERVICE_TYPES.map do |t| 
      [t.underscore.to_sym, services.where(type: t)]
    end.to_h.merge({ all: services })
  end

  def build_all_itineraries
    trip_itineraries = @trip_types.flat_map {|t| build_itineraries(t)}
    new_itineraries = trip_itineraries.reject(&:persisted?)
    old_itineraries = trip_itineraries.select(&:persisted?)

    Itinerary.transaction do
      old_itineraries.each(&:save!)
      @trip.itineraries += new_itineraries
    end
  end

  def filter_itineraries
    walk_seen = false
    max_walk_minutes = Config.max_walk_minutes
    max_walk_distance = Config.max_walk_distance
    itineraries = @trip.itineraries.map do |itin|
      next if itin.walk_time && itin.walk_time > max_walk_minutes * 60
      if itin.walk_time && itin.duration && itin.walk_time == itin.duration
        if walk_seen
          next 
        else 
          walk_seen = true 
        end
      end
      if !@trip.itineraries.map(&:trip_type).include?('walk') && itin.trip_type == 'transit' && 
        itin.legs.all? { |leg| leg['mode'] == 'WALK' } && 
        itin.walk_distance >= itin.legs.first['distance']
        next
      end
      if !@trip.itineraries.map(&:trip_type).include?('walk') && itin.trip_type == 'transit' && itin.legs.detect { |leg| leg['mode'] == 'WALK' && leg["distance"] > max_walk_distance }
        next
      end
      if !@trip.itineraries.map(&:trip_type).include?('walk')
        if itin.trip_type == 'transit' && itin.legs.any? { |leg| leg['mode'] == 'WALK' && leg["distance"] > max_walk_distance }
          next
        end
      end
      itin
    end.compact
    @trip.itineraries = itineraries
  end

  def check_no_valid_services
    no_transit = true
    no_paratransit = true
    @trip.itineraries.each do |itin|
      if itin.trip_type == "transit"
        no_transit = false
      elsif itin.trip_type == "paratransit"
        no_paratransit = false
      end
    end
    @trip.no_valid_services = no_paratransit && no_transit
  end

  def build_itineraries(trip_type)
    catch_errors(trip_type)
    self.send("build_#{trip_type}_itineraries")
  end

  def catch_errors(trip_type)
    errors = @router.errors(trip_type)
    @errors << errors if errors
  end

  def build_transit_itineraries
    build_fixed_itineraries :transit
  end

  def build_car_park_itineraries
    build_fixed_itineraries :car_park
  end

  def build_walk_itineraries
    build_fixed_itineraries :walk
  end

  def build_car_itineraries
    build_fixed_itineraries :car
  end

  def build_bicycle_itineraries
    build_fixed_itineraries :bicycle
  end

  def build_paratransit_itineraries
    return [] unless @available_services[:paratransit].present?

    router_paratransit_itineraries = []
    if Config.open_trip_planner_version == 'v2'
      otp_itineraries = build_fixed_itineraries(:paratransit).select { |itin| itin.service_id.present? }
      router_paratransit_itineraries += otp_itineraries.map do |itin|
        no_paratransit = true
        has_transit = false
        itin.legs.each do |leg|
          no_paratransit = false if leg['mode'].include?('FLEX')
          has_transit = true unless leg['mode'].include?('FLEX') || leg['mode'] == 'WALK'
        end
        if no_paratransit
          next nil
        end
        itin.trip_type = 'paratransit_mixed' if has_transit
        itin
      end.compact
    end

    paratransit_services = @available_services[:paratransit].where(gtfs_agency_id: ["", nil])
    allowed_api = Config.booking_api
    return router_paratransit_itineraries if allowed_api == "none"
    unless allowed_api == "all"
      paratransit_services = paratransit_services.where(booking_api: allowed_api)
    end

    itineraries = paratransit_services.map do |svc|
      Rails.logger.info("Checking service id: #{svc&.id}")
      if svc.booking_api == "ecolane" && UserBookingProfile.where(service: svc, user: @trip.user).count == 0 && @trip.user.registered?
        next nil
      end
      itinerary = Itinerary.left_joins(:booking)
                           .where(bookings: { id: nil })
                           .find_or_initialize_by(
                             service_id: svc.id,
                             trip_type: :paratransit,
                             trip_id: @trip.id
                           )
      itinerary.assign_attributes({
        assistant: @options[:assistant],
        companions: @options[:companions],
        cost: svc.fare_for(@trip, router: @router, companions: @options[:companions], assistant: @options[:assistant]),
        transit_time: @router.get_duration(:paratransit) * @paratransit_drive_time_multiplier
      })
      itinerary
    end.compact

    router_paratransit_itineraries + itineraries
  end

  # Builds an uber itinerary populates transit_time based on OTP response
  def build_lyft_itineraries
    return [] unless @available_services[:lyft] # Return an empty array if no taxi services are available

    cost, price_quote_id = @lyft_ambassador.cost('lyft')

    # Don't return LYFT results if there are none.
    return [] if cost.nil? 

    new_itineraries = @available_services[:lyft].map do |svc|
      Itinerary.new(
        service: svc,
        trip_type: :lyft,
        cost: cost,
        transit_time: @router.get_duration(:lyft)
      )
    end

    new_itineraries.map do |itin|
      LyftExtension.new(
        itinerary: itin,
        price_quote_id: price_quote_id
      )
    end

    new_itineraries

  end

  # Generic OTP Call
  def build_fixed_itineraries trip_type
    @router.get_itineraries(trip_type).map {|i| Itinerary.new(i)}
  end

end
