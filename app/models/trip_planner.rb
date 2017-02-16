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
    @otp = OTPService.new(Config.otp)
    @errors = []

    puts "Trip Planner Initialized!", self.ai
  end

  # Constructs Itineraries for the Trip based on the options passed
  def plan
    if @modes.include?('transit')
      puts "Planning Transit Itineraries"
      build_transit_itineraries
    end
  end

  # Builds transit itineraries, using OTP by default
  def build_transit_itineraries
    response = otp_plan_trip({mode: "TRANSIT,WALK"})

    # Check if response is successful
    if response.failure?
      @errors << {message: "OTP Request Failed with #{response.code}, #{response.message}"}
      return false
    end

    response_body = JSON.parse(response.body)
    itineraries = response_body["plan"]["itineraries"]
    # If so CREATE ITINERARIES BASED ON RESPONSE
    @trip.itineraries << itineraries.map {|i| create_itinerary_from_otp(i)}

    # If not, describe issue and add it to the errors array
  end

  private

  def create_itinerary_from_otp(otp_itin)
    start_time = Time.at(otp_itin["startTime"].to_i/1000).in_time_zone
    end_time = Time.at(otp_itin["endTime"].to_i/1000).in_time_zone
    walk_time = otp_itin["walkTime"]
    transit_time = otp_itin["transitTime"]
    cost = otp_itin['fare']['fare']['regular']['cents'].to_f/100.0
    legs = otp_itin["legs"]
    attrs= {
      start_time: start_time,
      end_time: end_time,
      transit_time: transit_time,
      walk_time: walk_time,
      cost: cost,
      legs: legs
    }
    return Itinerary.create(attrs)
  end

  def otp_plan_trip(options={})
    @otp.plan(
      [@trip.origin.lat, @trip.origin.lng],
      [@trip.destination.lat, @trip.destination.lng],
      @trip.trip_time,
      @trip.arrive_by,
      options
    )
  end

end
