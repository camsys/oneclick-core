class OTPAmbassador
  attr_reader :otp, :trip, :trip_types, :responses, :http_request_bundler

  # Translates 1-click trip_types into OTP mode requests
  TRIP_TYPE_DICTIONARY = {
    transit:      { label: :otp_transit,  modes: "TRANSIT,WALK" },
    paratransit:  { label: :otp_drive,    modes: "CAR" },
    taxi:         { label: :otp_drive,    modes: "CAR" },
<<<<<<< HEAD
    walk:         { label: :otp_walk,     modes: "WALK"},
    drive:        { label: :otp_drive,    modes: "CAR"},
    bicycle:      { label: :otp_bicycle,  modes: "BICYCLE"}
=======
    walk:         { label: :otp_walk,     modes: "WALK"}
>>>>>>> master
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
    return {itineraries: itineraries.map {|i| translate_itinerary(i, trip_type)}}
  end

  def get_duration(trip_type)
    return 0 if errors(trip_type)
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
  def translate_itinerary(otp_itin, trip_type)
    start_time = Time.at(otp_itin["startTime"].to_i/1000).in_time_zone
    end_time = Time.at(otp_itin["endTime"].to_i/1000).in_time_zone
<<<<<<< HEAD
    walk_time = get_walk_time(otp_itin, trip_type)
    transit_time = get_transit_time(otp_itin, trip_type)
=======
    walk_time = otp_itin["walkTime"]
    transit_time = otp_itin["transitTime"]
>>>>>>> master
    cost = extract_cost(otp_itin, trip_type)
    legs = otp_itin["legs"]
    return {
      start_time: start_time,
      end_time: end_time,
      transit_time: transit_time,
      walk_time: walk_time,
      cost: cost,
      legs: legs,
      trip_type: trip_type #TODO: Make this smarter
    }
  end

  # OTP Lists Drive and Walk as having 0 transit time
  def get_transit_time(otp_itin, trip_type)
    if trip_type.in? [:drive, :bicycle]
      return otp_itin["walkTime"]
    else
      return otp_itin["transitTime"]
    end
  end

  # OTP returns drive and bicycle time as walk time 
  def get_walk_time otp_itin, trip_type
    if trip_type.in? [:drive, :bicycle]
      return 0
    else
      return otp_itin["walkTime"]
    end
  end

  # Extracts cost from OTP itinerary
  def extract_cost(otp_itin, trip_type)
    # OTP returns a nil cost for walk trips.  nil means unknown, so it should be zero instead
<<<<<<< HEAD
    if trip_type.in? [:walk, :bicycle]
      return 0.0
    end

=======
    if trip_type.in? [:walk]
      return 0.0
    end
>>>>>>> master
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
