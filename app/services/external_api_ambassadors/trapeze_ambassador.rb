class TrapezeAmbassador < BookingAmbassador

  attr_accessor :url, :api_user, :api_token, :client_code
  
  # Calls super and then sets proper default for URL and Token
  def initialize(opts={})
    super(opts)
    @url ||= Config.trapeze_url
    @api_user ||= Config.trapeze_user
    @api_token ||= Config.trapeze_token
    @client = create_client(Config.trapeze_url, Config.trapeze_url, @api_user, @api_token)
    @client_code = nil
    @cookies = nil #Cookies are used to login the user
  end

  #####################################################################
  ## Top-Level Required Methods in order for BookingAmbassador to work
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
    response = pass_create_trip

    return false unless response && response[:pass_create_trip_response][:pass_create_trip_result][:booking_id].to_s != "-1"
        
    # Store the status info in a Booking object and return it
    update_booking(response)
    return booking
  end

  def cancel
    pass_cancel_trip
    # Derek Update the itinerary to show that it has ben un-booked
  end

  # Returns an array of question objects for RidePilot booking
  def prebooking_questions

    # this is a patch
    if @url.blank? or @api_token.blank?
      return []
    end

    [
      {
        question: "What is your blah blah?", 
        choices: [0,1,2,3], 
        code: "guests"
      },
      {
        question: "How many attendants will be riding with you?", 
        choices: [0,1,2,3], 
        code: "attendants"
      },
      {
        question: "What is your trip purpose?", 
        choices: [1,2,4], 
        code: "purpose"
      }
    ]
  end

  #####################################################################
  ## SOAP Calls to Trapeze
  #####################################################################
  def pass_validate_client_password
    begin
      response = @client.call(:pass_validate_client_password, message: {client_id: customer_id, password: customer_token})
    rescue => e
      Rails.logger.error e.message 
      return false
    end
    Rails.logger.info response.to_hash
    return response 
  end

  # Books the passed trip via RidePilot
  def pass_create_trip
    # Only attempt to create trip if all the necessary pieces are there
    return false unless @itinerary && @trip && @service && @user
    login if @cookies.nil? 
    response = @client.call(:pass_create_trip, message: trip_hash, cookies: @cookies)
    return response.to_hash

  end

  # Get Client Info
  def pass_get_client_info
    login if @cookies.nil? 
    response = @client.call(:pass_get_client_info, message: {client_id: customer_id, password: customer_token}, cookies: @cookies)
    Rails.logger.info response.to_hash
    return response.to_hash[:pass_get_client_info_response]
  end

  # Cancel the trip
  def pass_cancel_trip
    login if @cookies.nil? 
    message = {booking_id: booking_id, sched_status: 'CA'}
    result = @client.call(:pass_cancel_trip, message: message, cookies: @cookies)
    result.hash
  end

  # Get Trip Purposes for the specific user
  def pass_get_booking_purposes
    login if @cookies.nil?
    result = @client.call(:pass_get_booking_purposes, cookies: @cookies)
    result.hash
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
    result = pass_validate_client_password
    @cookies = result.http.cookies
    @client_code = result.to_hash[:pass_validate_client_password_response][:pass_validate_client_password_result][:client_code]
  end


  def origin_hash
    if @itinerary.nil?
      return nil
    end
    place_hash @itinerary.trip.origin
  end

  def destination_hash
    if @itinerary.nil?
      return nil
    end
    place_hash @itinerary.trip.destination
  end

  def place_hash place
    {
      address_mode: 'ZZ', 
      street_no: (place.street_number || "").upcase, 
      on_street: (place.route || "").upcase, 
      unit: ("").upcase, 
      city: (place.city|| "").upcase, 
      state: (place.state || "").upcase, 
      zip_code: place.zip, 
      lat: (place.lat*1000000).to_i, 
      lon: (place.lng*1000000).to_i, 
      geo_status:  -2147483648 
    }
  end

  def trip_hash

     # Create Pickup/Dropoff Hashes
    if @trip.arrive_by
      pu_leg_hash = {request_address: origin_hash}
      do_leg_hash = {req_time: @trip.trip_time.in_time_zone.seconds_since_midnight, request_address: destination_hash}
    else
      do_leg_hash = {request_address: destination_hash}
      pu_leg_hash = {req_time: @trip.trip_time.in_time_zone.seconds_since_midnight, request_address: origin_hash}
    end
    
    return {
      client_id: customer_id.to_i, 
      client_code: @client_code, 
      date: @trip.trip_time.strftime("%Y%m%d"), 
      booking_type: 'C', 
      para_service_id: para_service_id, 
      auto_schedule: true, 
      calculate_pick_up_req_time: true, 
      booking_purpose_id: 1, 
      pick_up_leg: pu_leg_hash, 
      drop_off_leg: do_leg_hash
    }
  
  end

  def get_funding_source_array
    ada_funding_sources = Config.trapeze_ada_funding_sources
    ignore_polygon = Config.trapeze_ignore_polygon_id
    check_polygon = Config.trapeze_check_polygon_id
  end

  # Gets the Trapeze Booking Id from the booking object
  def booking_id
    booking.try(:confirmation)
  end

  def trapeze_purposes
    result = pass_get_booking_purposes
    #Derek makes this arrayify
    result.to_hash[:envelope][:body][:pass_get_booking_purposes_response][:pass_get_booking_purposes_result][:pass_booking_purpose].map{|v| {name: v[:description],  code: v[:booking_purpose_id]}}
    #result.to_hash[:envelope][:body][:pass_get_booking_purposes_response][:pass_get_booking_purposes_result][:pass_booking_purpose]
  end

    # returns a hash of booking attributes from a RidePilot response
  def booking_attrs_from_response(response)
    {
      type: "TrapezeBooking",
      details: response.try(:with_indifferent_access),
      status: "saved",
      confirmation: response.try(:with_indifferent_access).try(:[], "pass_create_trip_response").try(:[], "pass_create_trip_result").try(:[], "booking_id")
    }
  end

  # Updates trip booking object with response
  def update_booking(response)

    return false unless response
    booking.try(:update_attributes, booking_attrs_from_response(response))
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


end
