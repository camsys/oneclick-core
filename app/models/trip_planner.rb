###
# TRIP PLANNER is in charge of handling the business logic around building
# itineraries for a trip, and pulling in information from various 3rd-party
# APIs.

class TripPlanner

  attr_reader :trip, :options, :otp, :errors

  # Initialize with a Trip object, and an options hash
  def initialize(trip, options={})
    @trip = trip
    @options = options
    @modes = options[:modes]
    @otp = OTPAmbassador.new(Config.open_trip_planner)
    @errors = []
  end

  # Constructs Itineraries for the Trip based on the options passed
  def plan
    itineraries = []
    itineraries += transit_itineraries if @modes.include?('transit')
    @trip.itineraries += itineraries
  end

  # Builds transit itineraries, using OTP by default
  def transit_itineraries
    response = @otp.plan(@trip, {mode: "TRANSIT,WALK"})
    if response[:error]
      @errors << response
      return []
    elsif response[:itineraries]
      return response[:itineraries].map {|i| Itinerary.create(i)}
    else
      return []
    end
  end

end
