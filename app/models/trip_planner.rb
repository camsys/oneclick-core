###
# TRIP PLANNER is in charge of handling the business logic around building
# itineraries for a trip, and pulling in information from various 3rd-party
# APIs.

class TripPlanner

  attr_reader :trip, :options, :router, :errors

  # Initialize with a Trip object, and an options hash
  def initialize(trip, options={})
    @trip = trip
    @options = options
    @modes = options[:modes]
    @router = options[:router] || OTPAmbassador.new(@trip)
    @errors = []
    @paratransit_drive_time_multiplier = 2.5
  end

  # Constructs Itineraries for the Trip based on the options passed
  def plan
    itineraries = []
    itineraries += transit_itineraries if @modes.include?('transit')
    itineraries += paratransit_itineraries if @modes.include?('paratransit')
    @trip.itineraries += itineraries
  end

  # Builds transit itineraries, using OTP by default
  def transit_itineraries
    response = @router.get_transit_itineraries
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
  def paratransit_itineraries
    Paratransit.all.map do |service|
      Itinerary.create(service: service, transit_time: @router.drive_time * @paratransit_drive_time_multiplier)
    end
  end

end
