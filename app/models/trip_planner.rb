###
# TRIP PLANNER is in charge of handling the business logic around building
# itineraries for a trip, and pulling in information from various 3rd-party
# APIs.

class TripPlanner

  # Constant list of trip types that can be planned.
  TRIP_TYPES = Trip::TRIP_TYPES
  attr_reader :trip, :options, :router, :errors, :trip_types, :available_services, :http_request_bundler
  attr_reader :relevant_purposes, :relevant_accommodations, :relevant_eligibilities

  # Initialize with a Trip object, and an options hash
  def initialize(trip, options={})
    @trip = trip
    @options = options
    @trip_types = (options[:trip_types] || TRIP_TYPES) & TRIP_TYPES # Set to only valid trip_types, all by default
    @errors = []
    @paratransit_drive_time_multiplier = 2.5
    @available_services = nil
    # This bundler is passed to the ambassadors, so that all API calls can be made asynchronously
    @http_request_bundler = options[:http_request_bundler] || HTTPRequestBundler.new
    @relevant_eligibilities = @relevant_purposes = @relevant_accommodations = []
  end

  # Constructs Itineraries for the Trip based on the options passed
  def plan
    # Prepares relevant instance variables and services
    prepare_for_plan_call

    # Build itineraries for each requested trip_type, then save the trip
    @trip.itineraries += @trip_types.flat_map {|t| build_itineraries(t)}
    @trip.save
  end

  # Identify available services and set up external API ambassadors
  def prepare_for_plan_call
    # Identify available services and set instance variable for use in building itineraries
    @available_services = available_services

    # Set up external API ambassadors for route finding and fare calculation
    @router = options[:router] || OTPAmbassador.new(@trip, @trip_types, @http_request_bundler, @available_services[:transit])
    @taxi_ambassador = options[:taxi_ambassador] || TFFAmbassador.new(@trip, @http_request_bundler, services: @available_services[:taxi])
    @uber_ambassador = options[:uber_ambassador] || UberAmbassador.new(@trip, @http_request_bundler)
  end

  # Identifies available services for the trip and requested trip_types, and sorts them by service type
  def available_services
    # Start with the scope of all services available for public viewing
    @services = Service.published
    
    # Only select services that match the requested trip types
    @services = @services.by_trip_type(*@trip_types)
    
    # Find all the services that are available for your time and locations
    @services = @services.available_for(@trip, except_by: [:purpose, :eligibility, :accommodation])

    # Pull out the relevant purposes, eligbilities, and accommodations of these services
    @relevant_purposes = (@services.collect { |service| service.purposes }).flatten.uniq
    @relevant_eligibilities = (@services.collect { |service| service.eligibilities }).flatten.uniq
    @relevant_accommodations = (@services.collect { |service| service.accommodations }).flatten.uniq

    # Now finish filtering by purpose, eligibility, and accommodation
    @services = @services.available_for(@trip, only_by: [:purpose, :eligibility, :accommodation])
    
    # Group available services by type, returning a hash with a key for each
    # service type, and one for all the available services
    Service::SERVICE_TYPES.map do |t| 
      [t.underscore.to_sym, @services.where(type: t)]
    end.to_h.merge({ all: @services })
  end

  # Calls the requisite trip_type itineraries method
  def build_itineraries(trip_type)
    catch_errors(trip_type)
    self.send("build_#{trip_type}_itineraries")
  end

  # Catches errors associated with a trip type and saves them in @errors
  def catch_errors(trip_type)
    errors = @router.errors(trip_type)
    @errors << errors if errors
  end

  # # # Builds transit itineraries, using OTP by default
  def build_transit_itineraries
    build_fixed_itineraries :transit
  end

  # Builds walk itineraries, using OTP by default
  def build_walk_itineraries
    build_fixed_itineraries :walk
  end

  def build_car_itineraries
    build_fixed_itineraries :car
  end

  def build_bicycle_itineraries
    build_fixed_itineraries :bicycle
  end

  # Builds paratransit itineraries for each service, populates transit_time based on OTP response
  def build_paratransit_itineraries
    return [] unless @available_services[:paratransit] # Return an empty array if no paratransit services are available

    @available_services[:paratransit].map do |svc|
      Itinerary.new(
        service: svc,
        trip_type: :paratransit,
        cost: svc.fare_for(@trip, router: @router),
        transit_time: @router.get_duration(:paratransit) * @paratransit_drive_time_multiplier,
      )
    end
  end

  # Builds taxi itineraries for each service, populates transit_time based on OTP response
  def build_taxi_itineraries
    return [] unless @available_services[:taxi] # Return an empty array if no taxi services are available
    @available_services[:taxi].map do |svc|
      Itinerary.new(
        service: svc,
        trip_type: :taxi,
        cost: svc.fare_for(@trip, router: @router, taxi_ambassador: @taxi_ambassador),
        transit_time: @router.get_duration(:taxi)
      )
    end
  end

  # Builds an uber itinerary populates transit_time based on OTP response
  def build_uber_itineraries
    return [] unless @available_services[:uber] # Return an empty array if no taxi services are available

    cost, product_id = @uber_ambassador.cost('uberX')
    new_itineraries = @available_services[:uber].map do |svc|
      Itinerary.new(
        service: svc,
        trip_type: :uber,
        cost: cost,
        transit_time: @router.get_duration(:uber)
      )
    end

    new_itineraries.map do |itin|
      UberExtension.new(
        itinerary: itin,
        product_id: product_id
      )
    end

    new_itineraries

  end

  # Generic OTP Call
  def build_fixed_itineraries trip_type
    @router.get_itineraries(trip_type).map {|i| Itinerary.new(i)}
  end

end
