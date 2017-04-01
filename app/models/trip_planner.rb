###
# TRIP PLANNER is in charge of handling the business logic around building
# itineraries for a trip, and pulling in information from various 3rd-party
# APIs.

class TripPlanner
  # Constant list of trip types that can be planned.
<<<<<<< HEAD
  TRIP_TYPES = [:transit, :paratransit, :taxi, :walk, :drive, :bicycle]
=======
  TRIP_TYPES = [:transit, :paratransit, :taxi, :walk]
>>>>>>> master

  attr_reader :trip, :options, :router, :errors, :trip_types, :available_services, :http_request_bundler

  # Initialize with a Trip object, and an options hash
  def initialize(trip, options={})
    @trip = trip
    @options = options
    @trip_types = (options[:trip_types] || TRIP_TYPES) & TRIP_TYPES # Set to only valid trip_types, all by default
    @errors = []
    @paratransit_drive_time_multiplier = 2.5
    @available_services = identify_available_services

    # This bundler is passed to the ambassadors, so that all API calls can be made asynchronously
    @http_request_bundler = options[:http_bundler] || HTTPRequestBundler.new

    # External API Ambassadors
    @router = options[:router] || OTPAmbassador.new(@trip, @trip_types, @http_request_bundler)
    @taxi_ambassador = options[:taxi_ambassador] || TFFAmbassador.new(@trip, @available_services[:taxi], @http_request_bundler)
  end

  # Constructs Itineraries for the Trip based on the options passed
  def plan
    @trip.itineraries += @trip_types.flat_map {|t| build_itineraries(t)}
    @trip.save
  end

  def identify_available_services
    @trip_types.map {|tt| [tt, get_available_services(tt)]}.to_h
  end

  def get_available_services(trip_type)
<<<<<<< HEAD
    unless trip_type.in? [:walk, :drive, :bicycle] 
=======
    unless trip_type.in? [:walk] 
>>>>>>> master
      trip_type.to_s.classify.constantize.available_for(@trip)
    end
  end

  # Calls the requisite trip_type itineraries method
  def build_itineraries(trip_type)
    self.send("build_#{trip_type}_itineraries")
  end

  # Builds transit itineraries, using OTP by default
  def build_transit_itineraries
    build_fixed_itineraries :transit
  end

  # Builds walk itineraries, using OTP by default
  def build_walk_itineraries
    build_fixed_itineraries :walk
<<<<<<< HEAD
  end

  def build_drive_itineraries
    build_fixed_itineraries :drive
  end

  def build_bicycle_itineraries
    build_fixed_itineraries :bicycle
=======
>>>>>>> master
  end

  # Builds paratransit itineraries for each service, populates transit_time based on OTP response
  def build_paratransit_itineraries
    response = @router.get_itineraries(:paratransit)
    @errors << response if response[:error]

    @available_services[:paratransit].map do |service|
      Itinerary.new(service: service, trip_type: :paratransit, transit_time: @router.get_duration(:paratransit) * @paratransit_drive_time_multiplier)
    end
  end

  # Builds taxi itineraries for each service, populates transit_time based on OTP response
  def build_taxi_itineraries
    response = @router.get_itineraries(:taxi)
    @errors << response if response[:error]

    @available_services[:taxi].map do |service|
      Itinerary.new(service: service, trip_type: :taxi, cost: @taxi_ambassador.fare(service), transit_time: @router.get_duration(:taxi))
    end
  end

  # Generic OTP Call
  def build_fixed_itineraries trip_type
    response = @router.get_itineraries(trip_type)
    if response[:error]
      @errors << response
      return []
    elsif response[:itineraries]
      return response[:itineraries].map {|i| Itinerary.new(i)}
    else
      return []
    end
  end

end
