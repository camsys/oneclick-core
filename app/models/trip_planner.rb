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
    @otp = OTPAmbassador.new(Config.otp)
    @errors = []
  end

  # Constructs Itineraries for the Trip based on the options passed
  def plan
    if @modes.include?('transit')
      puts "Planning Transit Itineraries"
      @trip.itineraries << transit_itineraries
    end
  end

  # Builds transit itineraries, using OTP by default
  def transit_itineraries
    response = @otp.plan(@trip, {mode: "TRANSIT,WALK"})
    return false if otp_response_failure(response)

    response_body = JSON.parse(response.body)
    itineraries = response_body["plan"]["itineraries"] || []
    # If so, create itineraries based on response
    return itineraries.map {|i| @otp.create_itinerary(i)}
  end

  private

  # Adds error to @errors and returns true if OTP Response was a failure
  def otp_response_failure(response)
    if response.failure?
      @errors << {message: "OTP Request Failed with #{response.code}, #{response.message}"}
      return true
    else
      return false
    end
  end

end
