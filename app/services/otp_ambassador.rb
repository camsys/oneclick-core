class OTPAmbassador
  attr_reader :otp

  def initialize(otp_url)
    @otp = OTPService.new(otp_url)
  end

  # Unpacks a trip and plans it via OTP
  def plan(trip, options={})
    @otp.plan(
      [trip.origin.lat, trip.origin.lng],
      [trip.destination.lat, trip.destination.lng],
      trip.trip_time,
      trip.arrive_by,
      options
    )
  end

  # Creates an itinerary from an OTP itinerary hash
  def create_itinerary(otp_itin)
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

end
