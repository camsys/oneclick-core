class TrapezeAmbassador < BookingAmbassador

  attr_accessor :url, :api_user, :api_token, :client_code, :client_info
  
  # Calls super and then sets proper default for URL and Token
  def initialize(opts={})
    super(opts)
    @url ||= Config.trapeze_url
    @api_user ||= Config.trapeze_user
    @api_token ||= Config.trapeze_token
    @client = create_client(Config.trapeze_url, Config.trapeze_url, @api_user, @api_token)
    @ada_funding_source_array = Config.trapeze_ada_funding_sources
    @trapeze_check_polygon_id = Config.trapeze_check_polygon_id
    @trapeze_ignore_polygon_id = Config.trapeze_ignore_polygon_id
    @client_code = nil #Will be filled out after logging in
    @cookies = nil #Cookies are used to login the user
    @passenger_types = nil # A list of all passengers types allowed for this user.  It's saved to avoid making the call multiple times.
    @booking_id = nil
    @client_info = nil
  end

  #####################################################################
  ## Top-level required methods in order for BookingAmbassador to work
  #####################################################################
  # Returns symbol for identifying booking api type
  def booking_api
    :trapeze
  end

  # Used to test if a Oneclick Service is setup correctly
  def authentic_provider?
    #TODO: Call Trapeze to Confirm that the ProviderID exists before allowing a Service to set it's ID
    true
  end

  # Returns True if a User is a valid Trapeze User
  def authenticate_user?
    response = pass_validate_client_password
    if response.to_hash[:pass_validate_client_password_response][:validation][:item][:code] == "RESULTOK"
      return true
    else
      return false
    end
  end

  def book
    # select the itinerary if not already selected
    @itinerary.select if @itinerary && !@itinerary.selected?

    # Make a create_trip call to Trapeze, passing a trip and any 
    # booking_options that have been set
    ## Sorted Funding Array
    get_funding_array.each do |funding|
      trip_hash = create_trip_hash(funding[:funding_source_id], funding[:fare_type_id], funding[:excluded_validation_checks])
      response = pass_create_trip trip_hash
      if response && response[:pass_create_trip_response][:pass_create_trip_result][:booking_id].to_s != "-1"
        set_booking_id(response)
        update_booking
        return booking 
      end
    end

    return false

  end

  def cancel
    pass_cancel_trip
    # Unselect the itinerary on successful cancellation
    @itinerary.unselect
    # Update Booking object with status info and return it
    update_booking
    return booking
  end

  def status
  end

  # Returns an array of question objects for RidePilot booking
  def prebooking_questions

    if @url.blank? or @api_token.blank?
      return []
    end

    [
      {
        question: "What is your trip purpose?", 
        choices: purpose_choices, 
        code: "purpose"
      },
      {
        question: "Are you traveling with anyone?", 
        choices: passenger_choices, 
        code: "guests"
      },
      { question: "What is your apartment number?",
        choices: ['string'],
        code: "pickup_unit_number"
      },
      { question: "What is the apartment number at your destination?",
        choices: ['string'],
        code: "dropoff_unit_number"
      }
    ]
  end

  # Get all future trips and trips within the past month 
  # Create 1-Click Trips for those trips if they don't already exist
  def sync
    pass_get_client_trips.try(:with_indifferent_access).try(:[], :envelope).try(:[], :body).try(:[], :pass_get_client_trips_response).try(:[], :pass_get_client_trips_result).try(:[], :pass_booking).each do |booking|
      occ_trip_from_trapeze_trip booking
    end 
  end

  #####################################################################
  ## SOAP Calls to Trapeze
  #####################################################################
  def pass_validate_client_password
    begin
      response = @client.call(:pass_validate_client_password, message: {client_id: customer_id, password: customer_token})
    rescue => e
      Rails.logger.error e.message.ai 
      return false
    end
    Rails.logger.info response.to_hash.ai 
    return response 
  end

  # Books the passed trip via RidePilot
  def pass_create_trip trip_hash
    # Only attempt to create trip if all the necessary pieces are there
    return false unless @itinerary && @trip && @service && @user
    login if @cookies.nil? 
    Rails.logger.info trip_hash.ai 
    response = @client.call(:pass_create_trip, message: trip_hash, cookies: @cookies).to_hash
    Rails.logger.info response.to_hash.ai 
    return response 
  end

  # Get Client Info
  def pass_get_client_info
    login if @cookies.nil? 
    return @client_info if @client_info
    response = @client.call(:pass_get_client_info, message: {client_id: customer_id, password: customer_token}, cookies: @cookies)
    Rails.logger.info response.to_hash.ai
    @client_info = response.to_hash[:pass_get_client_info_response]
    return @client_info
  end

  # Cancel the trip
  def pass_cancel_trip
    login if @cookies.nil? 
    message = {booking_id: booking_id, sched_status: 'CA'}
    @client.call(:pass_cancel_trip, message: message, cookies: @cookies).hash
  end

  # Get Trip Purposes for the specific user
  def pass_get_booking_purposes
    login if @cookies.nil?

    # Don't return trip purposes for a non-logged in user
    return nil if @cookies.nil?

    response = @client.call(:pass_get_booking_purposes, cookies: @cookies).hash
    Rails.logger.info response.to_hash.ai
    return response 

  end

  # Get a List of Passenger Types
  def pass_get_passenger_types
    #Login
    login if @cookies.nil?
    return nil if @cookies.nil?
    
    return @passenger_types unless @passenger_types.nil?
    message = {client_id: customer_id}
    @passenger_types = @client.call(:pass_get_passenger_types, message: message, cookies: @cookies).hash
    return @passenger_types
  end
  
  # Get Client Trips
  def pass_get_client_trips from_date=nil, to_date=nil, booking_id=nil
    login if @cookies.nil?
    message = {}

    #Add the parameters to the request.
    if from_date 
      message[:from_date] = from_date.strftime("%Y%m%d")
    end
    if to_date 
      message[:to_date] = to_date.strftime("%Y%m%d")
    end
    if booking_id
      message[:booking_id] = booking_id
    end

    @client.call(:pass_get_client_trips, message: message, cookies: @cookies).hash
  end

  #####################################################################
  ## Helper Methods
  #####################################################################
  # Gets the customer id from the user's booking profile
  def customer_id
    @booking_profile.try(:external_user_id)
  end

  # Gets the customer token from the user's booking profile  b
  def customer_token
    @booking_profile.try(:external_password)
  end

  # Return the Trapeze ID of the Service
  def para_service_id
    return nil unless @service
    @service.booking_details["trapeze_provider_id"]
  end

  # Login the Client
  def login
    return false unless (customer_id and customer_token) 
    result = pass_validate_client_password
    @cookies = result.http.cookies

    #@client_code = result.to_hash[:pass_validate_client_password_response][:pass_validate_client_password_result][:client_code]
    @client_code = result.to_hash.try(:with_indifferent_access).try(:[], "pass_validate_client_password_response").try(:[], "pass_validate_client_password_result").try(:[],"client_code")
    unless @client_code
      @cookies = nil 
      return false
    end
    true 
  end

  # Build a Trapeze Place Hash for the Origin
  def origin_hash
    if @itinerary.nil?
      return nil
    end
    place_hash(@itinerary.trip.origin, @booking_options[:pickup_unit_number])
  end

  # Build a Trapeze Place Hash for the Destination
  def destination_hash
    if @itinerary.nil?
      return nil
    end
    place_hash(@itinerary.trip.destination, @booking_options[:dropoff_unit_number])
  end

  # Pass an OCC Place, get a Trapeze Place
  def place_hash(place, unit) 
    {
      address_mode: 'ZZ', 
      street_no: (place.street_number || "").upcase, 
      on_street: (place.route || "").upcase, 
      unit: (unit || "").upcase, 
      city: (place.city|| "").upcase, 
      state: (place.state || "").upcase, 
      zip_code: place.zip, 
      lat: (place.lat*1000000).to_i, 
      lon: (place.lng*1000000).to_i, 
      geo_status:  -2147483648 
    }
  end

  # Builds the payload for creating a trip
  def create_trip_hash(funding_source_id, fare_type_id, excluded_validation_checks)

     # Create Pickup/Dropoff Hashes
    if @trip.arrive_by
      pu_leg_hash = {request_address: origin_hash}
      do_leg_hash = {req_time: @trip.trip_time.in_time_zone.seconds_since_midnight, request_address: destination_hash}
    else
      do_leg_hash = {request_address: destination_hash}
      pu_leg_hash = {req_time: @trip.trip_time.in_time_zone.seconds_since_midnight, request_address: origin_hash}
    end
    
    request_hash = {
      client_id: customer_id.to_i, 
      client_code: @client_code, 
      date: @trip.trip_time.strftime("%Y%m%d"), 
      booking_type: 'C', 
      para_service_id: para_service_id, 
      auto_schedule: true, 
      calculate_pick_up_req_time: true, 
      booking_purpose_id: 2, #@booking_options[:purpose], 
      pick_up_leg: pu_leg_hash, 
      drop_off_leg: do_leg_hash
    }

    # Check to see if another passenger is coming
    if @booking_options[:guests] != "NONE"
      request_hash[:companion_mode] = "S"
      request_hash[:pass_booking_passengers] = [passenger_hash(@booking_options[:guests])]
    end

    # Deal with Funding Sources
    request_hash[:excluded_validation_checks] = excluded_validation_checks
    request_hash[:funding_source_id] = funding_source_id
    request_hash[:fare_type_id] = fare_type_id

    return request_hash
  
  end

  # Returns a sorted array of funding sources, fare types, and exclusion rules
  # fuding[:funding_source_id], funding[:fare_type_id], funding[:excluded_validation_checks]
  def get_funding_array
    #return [{priority: 1, funding_source_name: "ADA", funding_source_id: 8, fare_type_id: 1, excluded_validation_checks: 18}]
    funding_array  = []
    client_info = pass_get_client_info
    
    # Iterate over this client's funding sources and create a hash.
    #client_info[:pass_get_client_info_result][:pass_client_funding_sources][:pass_client_funding_source].each do |fs|
    client_funding_source_array = client_info.try(:with_indifferent_access).try(:[], :pass_get_client_info_result).try(:[], :pass_client_funding_sources).try(:[], :pass_client_funding_source)
    arrayify(client_funding_source_array).each do |fs|
    
      is_ada = fs[:funding_source_id].in? @ada_funding_source_array
      # For ADA Trips set the sequence to -1
      funding_array << { 
        sequence: is_ada ? "-1" : fs[:sequence],
        funding_source_id: fs[:funding_source_id],
        fare_type_id: 1,
        excluded_validation_checks: is_ada ? @trapeze_check_polygon_id : @trapeze_ignore_polygon_id,
        funding_source_name: fs[:funding_source_name]
      }
    end
    return funding_array.sort_by{ |element| element[:sequence] }
  end

  def set_booking_id response
    @booking_id = response.try(:with_indifferent_access).try(:[], "pass_create_trip_response").try(:[], "pass_create_trip_result").try(:[], "booking_id")
  end

  # Gets the Trapeze Booking Id from the booking object
  def booking_id
    @booking_id || booking.try(:confirmation)
  end

  # Builds an array of allowed purposes to ask the user.  
  def purpose_choices
    result = pass_get_booking_purposes
    return [] if result.nil?
    result.to_hash[:envelope][:body][:pass_get_booking_purposes_response][:pass_get_booking_purposes_result][:pass_booking_purpose].map{|v| [v[:description], v[:booking_purpose_id]]}
  end

  # Builds an array of allowed passengers types.  Used to ask the user about passenger.
  def passenger_choices
    passenger_choices_array = [["NONE", "NONE"]]
    ##result = pass_get_passenger_types
    passenger_types_array.each do |purpose|
      passenger_choices_array.append([purpose.try(:[], :description), purpose.try(:[], :abbreviation)])
    end
    passenger_choices_array
  end

  def booking_attrs
    response = pass_get_client_trips(nil, nil, booking_id)

    # Calculate time window
    trap_trip = response.try(:with_indifferent_access).try(:[], :envelope).try(:[], :body).try(:[], :pass_get_client_trips_response).try(:[], :pass_get_client_trips_result).try(:[], :pass_booking)
    raw_date = trap_trip.try(:with_indifferent_access).try(:[], :raw_date).in_time_zone.to_time
    pick_up_leg = response.try(:with_indifferent_access).try(:[], :envelope).try(:[], :body).try(:[], :pass_get_client_trips_response).try(:[], :pass_get_client_trips_result).try(:[], :pass_booking).try(:[], :pick_up_leg)
    seconds_since_midnight = pick_up_leg.try(:with_indifferent_access).try(:[], :display_early)
    early_pu_time = raw_date + seconds_since_midnight.to_i.seconds
    seconds_since_midnight = pick_up_leg.try(:with_indifferent_access).try(:[], :display_late)
    late_pu_time = raw_date + seconds_since_midnight.to_i.seconds

    {
      type: "TrapezeBooking",
      details: response.try(:with_indifferent_access),
      status:  response.try(:with_indifferent_access).try(:[], :envelope).try(:[], :body).try(:[], :pass_get_client_trips_response).try(:[], :pass_get_client_trips_result).try(:[], :pass_booking).try(:[], :sched_status),
      confirmation: booking_id,
      earliest_pu: early_pu_time,
      latest_pu: late_pu_time
    }
    
  end

  # Updates trip booking object with response
  def update_booking
    Rails.logger.info booking_attrs.ai 
    booking.try(:update_attributes, booking_attrs)
  end


  # Builds a hash for bringing extra passengers 
  def passenger_hash passenger
    # Get the fare_type for this passenger from the mapping
    fare_type = passenger_type_funding_type_mapping[passenger]

    #Temp
    passenger = 'CLI'
    fare_type = 1

    {pass_booking_passenger: {passenger_type: passenger, space_type: "AM", passenger_count: 1, fare_type: fare_type}}
  end

  # Passenger Type to Funding Type Mapping
  # Each extra passenger type, must have it's own funding type.
  # 
  def passenger_type_funding_type_mapping
    mapping = {}
    passenger_types_array.each do |pass|
      mapping[pass.try(:with_indifferent_access).try(:[], :abbreviation)] = pass.try(:with_indifferent_access).try(:[], :fare_type_id)
    end
    mapping
  end

  def passenger_types_array 
    result = pass_get_passenger_types
    return [] if result.nil?
    result.try(:with_indifferent_access).try(:[], :envelope).try(:[], :body).try(:[], :pass_get_passenger_types_response).try(:[], :pass_get_passenger_types_result).try(:[], :pass_passenger_type)
  end

  #####################################################################
  ## Build OCC Components for Trapeze Components
  #####################################################################

  # Build OCC Trip, Itinerary, and Booking from a Trapeze Trip
  def occ_trip_from_trapeze_trip trap_trip
    booking_id = trap_trip.try(:with_indifferent_access).try(:[], :booking_id)
    itinerary = @user.itineraries.joins(:booking).find_by('bookings.confirmation = ? AND service_id = ?', booking_id, @service.id)

    # Calculate time window
    raw_date = trap_trip.try(:with_indifferent_access).try(:[], :raw_date).in_time_zone.to_time
    pick_up_leg = trap_trip.try(:with_indifferent_access).try(:[], :pick_up_leg)
    seconds_since_midnight = pick_up_leg.try(:with_indifferent_access).try(:[], :display_early)

    early_pu_time = raw_date + seconds_since_midnight.to_i.seconds
    seconds_since_midnight = pick_up_leg.try(:with_indifferent_access).try(:[], :display_late)
    late_pu_time = raw_date + seconds_since_midnight.to_i.seconds

    # This Trip has already been created, just update it with new times/status etc.
    if itinerary
      booking = itinerary.booking 
      booking.latest_pu = late_pu_time
      booking.earliest_pu = early_pu_time
      booking.status =  trap_trip.try(:with_indifferent_access).try(:[], :sched_status)
      if booking.status.in? TrapezeBooking::CANCELED_TRIP_STATUS_CODES
        itinerary.unselect
      end
      booking.save 
      return nil
    # This Trip needs to be added to OCC
    else
      # Make the Trip
      trip = Trip.create!(occ_trip_hash(trap_trip))
      # Make the Itinerary
      itinerary = Itinerary.new(occ_itinerary_hash_from_trapeze_trip(trap_trip))
      itinerary.trip = trip
      itinerary.save 
      itinerary.select

      # Make the Booking
      booking = Booking.new(occ_booking_hash(trap_trip))
      booking.latest_pu = late_pu_time
      booking.earliest_pu = early_pu_time
      booking.itinerary = itinerary
      if booking.status.in? TrapezeBooking::CANCELED_TRIP_STATUS_CODES
        itinerary.unselect
      end
      booking.save 
    end
  end

  def occ_place_from_trapeze_place trap_place
    Waypoint.create!(occ_place_hash(trap_place))
  end
  
  # Hashes
  def occ_trip_hash trap_trip
    origin = occ_place_from_trapeze_place(trap_trip.try(:with_indifferent_access).try(:[], :pick_up_leg))
    destination = occ_place_from_trapeze_place(trap_trip.try(:with_indifferent_access).try(:[], :drop_off_leg))
    arrive_by = arrive_by?(trap_trip)
    seconds_since_midnight = (arrive_by ? trap_trip.try(:with_indifferent_access).try(:[], :drop_off_leg).try(:[], :neg_time) : trap_trip.try(:with_indifferent_access).try(:[], :pick_up_leg).try(:[], :neg_time))
    trip_time = trap_trip.try(:with_indifferent_access).try(:[], :raw_date).to_time + seconds_since_midnight.to_i.seconds
    {user: @user, origin: origin, destination: destination, trip_time: trip_time, arrive_by: arrive_by}
  end

  def occ_place_hash trap_place
    map_address = trap_place.try(:with_indifferent_access).try(:[], :map_address)
    map_geo_code = trap_place.try(:with_indifferent_access).try(:[], :map_geo_code)
    {
      name:           map_address.try(:with_indifferent_access).try(:[], :addr_name),
      street_number:  map_address.try(:with_indifferent_access).try(:[], :street_no),
      route:          map_address.try(:with_indifferent_access).try(:[], :on_street),
      city:           map_address.try(:with_indifferent_access).try(:[], :city),
      zip:            map_address.try(:with_indifferent_access).try(:[], :zip_code),
      lat:            occ_latlng_from_trapeze_latlng(map_geo_code.try(:with_indifferent_access).try(:[], :lat)),
      lng:            occ_latlng_from_trapeze_latlng(map_geo_code.try(:with_indifferent_access).try(:[], :lon))
    }
  end 

  def occ_itinerary_hash_from_trapeze_trip trap_trip
    fare = trap_trip.try(:with_indifferent_access).try(:[], :fare_amount)
    day = trap_trip.try(:with_indifferent_access).try(:[], :raw_date).to_time
    neg_start_seconds = trap_trip.try(:with_indifferent_access).try(:[], :pick_up_leg).try(:[], :neg_time)
    neg_end_seconds = trap_trip.try(:with_indifferent_access).try(:[], :drop_off_leg).try(:[], :neg_time)
    {
      start_time: (neg_start_seconds == "-1") ? nil : day + neg_start_seconds.to_i.seconds, 
      end_time: (neg_end_seconds == "-1") ? nil : day + neg_end_seconds.to_i.seconds, 
      transit_time: (neg_end_seconds != "-1" and neg_start_seconds != "-1") ? neg_end_seconds - neg_start_seconds : nil, 
      cost: fare.to_f, 
      service: @service, 
      trip_type: 'paratransit'
    }
  end
  
  # Convert from Trapeze Format to OCC Format
  # e.g., convert "344533" to 34.4533 and convert "-817765" to -81.7765
  def occ_latlng_from_trapeze_latlng latlng
    precision = latlng.to_s.length
    latlng = latlng.to_f
    latlng < 0 ? (latlng/(10**(precision-3))) : (latlng/(10**(precision-2)))
  end

  def occ_booking_hash trap_trip 
    {confirmation: trap_trip.try(:with_indifferent_access).try(:[], :booking_id), type: "TrapezeBooking", status: trap_trip.try(:with_indifferent_access).try(:[], :sched_status)}
  end

  def arrive_by? trap_trip
    trap_trip.try(:with_indifferent_access).try(:[], :pick_up_leg).try(:[], :req_time) == "-1"
  end

  protected

  # Create a Client
  def create_client(endpoint, namespace, username, password)
    client = Savon.client do
      endpoint endpoint
      namespace namespace
      basic_auth [username, password]
      convert_request_keys_to :camelcase
    end
    client
  end

  def arrayify thing
    if thing.is_a? Array
      return thing
    else
      return [thing]
    end
  end 

end
