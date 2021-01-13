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
    @trip_types = (options[:trip_types] || TRIP_TYPES) & TRIP_TYPES # Set to only valid trip_types, all by default
    @errors = []
    @paratransit_drive_time_multiplier = 2.5
    @master_service_scope = options[:available_services] || Service.all # Allow pre-filtering of available services
    # This bundler is passed to the ambassadors, so that all API calls can be made asynchronously
    @http_request_bundler = options[:http_request_bundler] || HTTPRequestBundler.new
    @relevant_eligibilities = @relevant_purposes = @relevant_accommodations = []

    # Allow user to request that certain service availability filters be included or skipped
    @only_filters = (options[:only_filters] || Service::AVAILABILITY_FILTERS) & Service::AVAILABILITY_FILTERS
    @except_filters = options[:except_filters] || []
    @filters = @only_filters - @except_filters
    
    # Initialize ambassadors if passed as options
    @router = options[:router] #This is the otp_ambassador
    @taxi_ambassador = options[:taxi_ambassador]
    @uber_ambassador = options[:uber_ambassador]
    @lyft_ambassador = options[:lyft_ambassador]
  end

  # Constructs Itineraries for the Trip based on the options passed
  def plan
    # Identify available services and set instance variable for use in building itineraries
    set_available_services
    
    # Sets up external ambassadors
    prepare_ambassadors

    # Build itineraries for each requested trip_type, then save the trip
    build_all_itineraries

    # Run through post-planning filters
    filter_itineraries 
    @trip.save
  end

  # Set up external API ambassadors
  def prepare_ambassadors
    # Set up external API ambassadors for route finding and fare calculation
    @router ||= OTPAmbassador.new(@trip, @trip_types, @http_request_bundler, @available_services[:transit])
    @taxi_ambassador ||= TFFAmbassador.new(@trip, @http_request_bundler, services: @available_services[:taxi])
    @uber_ambassador ||= UberAmbassador.new(@trip, @http_request_bundler)
    @lyft_ambassador ||= LyftAmbassador.new(@trip, @http_request_bundler)
  end

  # Identifies available services for the trip and requested trip_types, and sorts them by service type
  # Only filter by filters included in the @filters array
  def set_available_services
    # Start with the scope of all services available for public viewing
    @available_services = @master_service_scope.published

    # Only select services that match the requested trip types
    @available_services = @available_services.by_trip_type(*@trip_types)

    # Only select services that your age makes you eligible for
    # Enabling this line makes AGE act like and AND and not an OR with other eligibilities
    #if @trip.user and @trip.user.age 
    #  @available_services = @available_services.by_max_age(@trip.user.age).by_min_age(@trip.user.age)
    #end

    # Find all the services that are available for your time and locations
    @available_services = @available_services.available_for(@trip, only_by: (@filters - [:purpose, :eligibility, :accommodation]))

    # Pull out the relevant purposes, eligbilities, and accommodations of these services
    @relevant_purposes = (@available_services.collect { |service| service.purposes }).flatten.uniq
    @relevant_eligibilities = (@available_services.collect { |service| service.eligibilities }).flatten.uniq.sort_by{ |elig| elig.rank }
    @relevant_accommodations = Accommodation.all.ordered_by_rank

    # Now finish filtering by purpose, age, eligibility, and accommodation
    ### Split off services that are available by age    
    @available_by_age = @available_services.none
    if @trip.user and @trip.user.age 
      @available_by_age = (@available_services.by_max_age(@trip.user.age) + @available_services.by_min_age(@trip.user.age)).uniq
    end

    @not_available_by_age = @available_services - @available_by_age
    
    #Filter age eligible and not age eligible separately and then join them back together
    @not_available_by_age =  @not_available_by_age.available_for(@trip, only_by: (@filters & [:purpose, :eligibility, :accommodation]))
    @available_by_age =  @available_by_age.available_for(@trip, only_by: (@filters & [:purpose, :accommodation]))

    @available_services = (@available_by_age + @not_available_by_age).uniq

    # Now convert into a hash grouped by type
    @available_services = available_services_hash(@available_services)

  end
  
  # Group available services by type, returning a hash with a key for each
  # service type, and one for all the available services
  def available_services_hash(services)
    Service::SERVICE_TYPES.map do |t| 
      [t.underscore.to_sym, services.where(type: t)]
    end.to_h.merge({ all: services })
  end
  
  # Builds itineraries for all trip types
  def build_all_itineraries
    @trip.itineraries += @trip_types.flat_map {|t| build_itineraries(t)}
  end

  # Additional sanity checks can be applied here.
  def filter_itineraries
    walk_seen = false
    itineraries = @trip.itineraries.map do |itin|

      ## Test: Make sure we never exceed the maximium walk time
      max_walk_minutes = Config.max_walk_minutes || 45
      if itin.walk_time and itin.walk_time > max_walk_minutes*60
        next
      end

      ## Test: Make sure that we only ever return 1 walk trip
      if itin.walk_time and itin.duration and itin.walk_time == itin.duration 
        if walk_seen
          next 
        else 
          walk_seen = true 
        end
      end

      ## We've passed all the tests
      itin 
    end
    itineraries.delete(nil)
    @trip.itineraries = itineraries
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

    itineraries = @available_services[:paratransit].map do |svc|
      
      #TODO: this is a hack and needs to be replaced.
      # For FindMyRide, we only allow RideShares service to be returned if the user is associated with it.
      # If the service is an ecolane service and NOT the ecolane service that the user belongs do, then skip it.
      if svc.booking_api == "ecolane" and UserBookingProfile.where(service: svc, user: @trip.user).count == 0 and @trip.user.registered?
        next
      end 
      Itinerary.new(
        service: svc,
        trip_type: :paratransit,
        cost: svc.fare_for(@trip, router: @router),
        transit_time: @router.get_duration(:paratransit) * @paratransit_drive_time_multiplier,
      )

    end

    # Get rid of nil itineraries caused by skipping Ecolane Services
    itineraries.delete(nil)

    if itineraries.blank? 
      return []
    else 
      return itineraries 
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
    return [] unless @available_services[:uber] # Return an empty array if no Uber services are available

    cost, product_id = @uber_ambassador.cost('uberX')

    return [] unless cost

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
