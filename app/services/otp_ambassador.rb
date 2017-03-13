class OTPAmbassador
  attr_reader :otp, :trip

  def initialize(trip)
    @trip = trip
    @otp = OTPService.new(Config.open_trip_planner)
    @drive_time = nil
  end

  # Plan a transit trip via OTP and send back itinerary hashes or errors
  def get_transit_itineraries
    response = plan(mode: "TRANSIT,WALK")

    errors = otp_response_failure(response)
    return errors if errors

    response_body = JSON.parse(response.body)

    itineraries = response_body["plan"]["itineraries"] || []
    return {itineraries: itineraries.map {|i| translate_itinerary(i)}}
  end

  # Returns drive_time instance variable if already calculated, or makes a call
  # to OTP to get it.
  def drive_time
    return @drive_time if @drive_time # Return @drive_time if it's already been calculated

    response = plan(mode: "CAR")

    errors = otp_response_failure(response)
    return errors if errors

    # Parse the response and pull out the duration to calculate drive time
    response_body = JSON.parse(response.body)
    itineraries = response_body["plan"]["itineraries"] || []
    @drive_time = itineraries[0]["duration"] if itineraries[0]

    return @drive_time
  end

  private

  # Unpacks a trip and plans it via OTP
  def plan(options={})
    response = @otp.plan(
      [@trip.origin.lat, @trip.origin.lng],
      [@trip.destination.lat, @trip.destination.lng],
      @trip.trip_time,
      @trip.arrive_by,
      options
    )
    return response
  end

  # Converts an OTP itinerary hash into a set of 1-Click itinerary attributes
  def translate_itinerary(otp_itin)
    start_time = Time.at(otp_itin["startTime"].to_i/1000).in_time_zone
    end_time = Time.at(otp_itin["endTime"].to_i/1000).in_time_zone
    walk_time = otp_itin["walkTime"]
    transit_time = otp_itin["transitTime"]
    cost = extract_cost(otp_itin)
    legs = otp_itin["legs"]
    return {
      start_time: start_time,
      end_time: end_time,
      transit_time: transit_time,
      walk_time: walk_time,
      cost: cost,
      legs: legs
    }
  end

  def extract_cost(otp_itin)
    otp_itin['fare'] &&
    otp_itin['fare']['fare'] &&
    otp_itin['fare']['fare']['regular'] &&
    otp_itin['fare']['fare']['regular']['cents'].to_f/100.0
  end

  # Adds error to @errors and returns true if OTP Response was a failure
  def otp_response_failure(response)
    if response.failure?
      return {error: "OTP Request Failed with #{response.code}, #{response.message}"}
    else
      return false
    end
  end

end
