class OTPAmbassador
  attr_reader :otp, :trip, :trip_types, :responses, :http_request_bundler

  # Translates 1-click trip_types into OTP mode requests
  TRIP_TYPE_DICTIONARY = {
    transit:      { label: :otp_transit,  modes: "TRANSIT,WALK" },
    paratransit:  { label: :otp_drive,    modes: "CAR" },
    taxi:         { label: :otp_drive,    modes: "CAR" }
  }

  # Initialize with a trip and an array of trip types
  def initialize(trip, trip_types, http_request_bundler)
    @trip = trip
    @trip_types = trip_types
    @http_request_bundler = http_request_bundler
    @request_types = @trip_types.map { |tt| TRIP_TYPE_DICTIONARY[tt] }.uniq
    @otp = OTPService.new(Config.open_trip_planner)
    @responses = {}

    # add http calls to bundler based on trip and modes
    prepare_http_requests.each do |request|
      @http_request_bundler.add(request[:label], request[:url], request[:action])
    end
  end

  def get_itineraries(trip_type)
    return errors(trip_type) if errors(trip_type)
    itineraries = ensure_response(trip_type)["plan"]["itineraries"] || []
    return {itineraries: itineraries.map {|i| translate_itinerary(i)}}
  end

  def get_duration(trip_type)
    return errors(trip_type) if errors(trip_type)
    itineraries = ensure_response(trip_type)["plan"]["itineraries"] || []
    return itineraries[0]["duration"] if itineraries[0]
  end

  def get_request_url(request_type)
    @otp.plan_url(format_trip_as_otp_request(request_type))
  end

  private

  # Prepares a list of HTTP requests for the HTTP Request Bundler, based on request types
  def prepare_http_requests
    @request_types.map do |request_type|
      {
        label: request_type[:label],
        url: @otp.plan_url(format_trip_as_otp_request(request_type)),
        action: :get
      }
    end
  end

  # Formats the trip as an OTP request based on trip_type
  def format_trip_as_otp_request(trip_type)
    {
      from: [@trip.origin.lat, @trip.origin.lng],
      to: [@trip.destination.lat, @trip.destination.lng],
      trip_time: @trip.trip_time,
      arrive_by: @trip.arrive_by,
      label: trip_type[:label],
      options: { mode: trip_type[:modes] }
    }
  end

  # Packages and returns any errors that came back with a given trip request
  def errors(trip_type)
    response = ensure_response(trip_type)
    if response
      response_error = response["error"]
    else
      response_error = "No response for #{trip_type}."
    end
    response_error.nil? ? nil : { error: response_error }
  end

  # Fetches responses if they haven't already been stored
  def ensure_response(trip_type)
    trip_type_label = TRIP_TYPE_DICTIONARY[trip_type][:label]
    @http_request_bundler.response(trip_type_label)
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
      legs: legs,
      trip_type: :transit #TODO: Make this smarter
    }
  end

  # Extracts cost from OTP itinerary
  def extract_cost(otp_itin)
    otp_itin['fare'] &&
    otp_itin['fare']['fare'] &&
    otp_itin['fare']['fare']['regular'] &&
    otp_itin['fare']['fare']['regular']['cents'].to_f/100.0
  end

  # Processes and unpacks an OTP multi_plan responses hash
  def unpack_otp_responses(responses)
    Hash[responses[:callback].map do |type, resp|
      [type, JSON.parse(resp.response)]
    end]
  end


end
