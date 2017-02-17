class OTPAmbassador
  attr_reader :otp

  def initialize(otp_url)
    @otp = OTPService.new(otp_url)
  end

  # Unpacks a trip and plans it via OTP
  def plan(trip, options={})
    response = @otp.plan(
      [trip.origin.lat, trip.origin.lng],
      [trip.destination.lat, trip.destination.lng],
      trip.trip_time,
      trip.arrive_by,
      options
    )

    errors = otp_response_failure(response)
    return errors if errors

    response_body = JSON.parse(response.body)
    itineraries = response_body["plan"]["itineraries"] || []
    return {itineraries: itineraries.map {|i| translate_itinerary(i)}}
  end

  private

  # Converts an OTP itinerary hash into a set of 1-Click itinerary attributes
  def translate_itinerary(otp_itin)
    start_time = Time.at(otp_itin["startTime"].to_i/1000).in_time_zone
    end_time = Time.at(otp_itin["endTime"].to_i/1000).in_time_zone
    walk_time = otp_itin["walkTime"]
    transit_time = otp_itin["transitTime"]
    cost = otp_itin['fare']['fare']['regular']['cents'].to_f/100.0
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

  # Adds error to @errors and returns true if OTP Response was a failure
  def otp_response_failure(response)
    if response.failure?
      return {error: "OTP Request Failed with #{response.code}, #{response.message}"}
    else
      return false
    end
  end

end
