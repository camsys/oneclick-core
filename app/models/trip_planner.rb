###
# TRIP PLANNER is in charge of handling the business logic around building
# itineraries for a trip, and pulling in information from various 3rd-party
# APIs.

class TripPlanner
  # Constant list of trip types that can be planned.
  TRIP_TYPES = [:transit, :paratransit, :taxi]

  attr_reader :trip, :options, :router, :errors, :trip_types

  # Initialize with a Trip object, and an options hash
  def initialize(trip, options={})
    @trip = trip
    @options = options
    @trip_types = (options[:trip_types] || TRIP_TYPES) & TRIP_TYPES # Set to only valid trip_types, all by default
    @router = options[:router] || OTPAmbassador.new(@trip, @trip_types)
    @errors = []
    @paratransit_drive_time_multiplier = 2.5
    @tff_ambassador = options[:taxi_ambassador] || TFFAmbassador.new(@trip)
  end

  # Constructs Itineraries for the Trip based on the options passed
  def plan
    @trip.itineraries += @trip_types.flat_map {|t| build_itineraries(t)}
  end

  # Calls the requisite trip_type itineraries method
  def build_itineraries(trip_type)
    self.send("build_#{trip_type}_itineraries")
  end

  # Builds transit itineraries, using OTP by default
  def build_transit_itineraries
    response = @router.get_itineraries(:transit)
    if response[:error]
      @errors << response
      return []
    elsif response[:itineraries]
      return response[:itineraries].map {|i| Itinerary.create(i)}
    else
      return []
    end
  end

  # Builds paratransit itineraries for each service, populates transit_time based on OTP response
  def build_paratransit_itineraries
    Paratransit.available_for(@trip).map do |service|
      Itinerary.create(service: service, trip_type: :paratransit, transit_time: @router.get_duration(:paratransit) * @paratransit_drive_time_multiplier)
    end
  end

  # Builds taxi itineraries for each service, populates transit_time based on OTP response
  def build_taxi_itineraries
    Taxi.available_for(@trip).map do |service|
      Itinerary.create(service: service, trip_type: :taxi, cost: @tff_ambassador.fare(service), transit_time: @router.get_duration(:taxi))
    end 
  end

end
