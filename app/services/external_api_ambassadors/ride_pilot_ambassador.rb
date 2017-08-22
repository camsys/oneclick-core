class RidePilotAmbassador < BookingAmbassador
  
  # Calls super and then sets proper default for URL and Token
  def initialize(opts={})
    super(opts)
    @url ||= Config.ride_pilot_url
    @token ||= Config.ride_pilot_token
  end

  # Returns symbol for identifying booking api type
  def booking_api
    :ride_pilot
  end

  def book
    # select the itinerary if not already selected
    @itinerary.select if @itinerary && !@itinerary.selected?

    # Make a create_trip call to RidePilot, passing a trip and any 
    # booking_options that have been set
    response = create_trip
    return false unless response && response["trip_id"].present?
        
    # Store the status info in a Booking object and return it
    update_booking(response)
    return booking
  end
  
  def cancel
    # Make a cancel_trip call to RidePilot, using @trip
    response = cancel_trip
    return false unless response && response["trip_id"].present?
    
    # Unselect the itinerary on successful cancellation
    @itinerary.unselect

    # Update Booking object with status info and return it
    update_booking(response)
    return booking
  end
  
  def status
    # Make a get_status call to RidePilot, using @trip
    response = trip_status
    return false unless response && response["trip_id"].present?
    
    # Update Booking object with status info and return it
    update_booking(response)
    return booking
  end
  
  # Returns boolean true/false if user is a RidePilot user
  def authenticate_user?
    authenticate_customer == "200 OK"
  end


  ### API CALLS ###
  
  # Authenticates a RidePilot Provider
  def authenticate_provider    
    label = request_label(:authenticate_provider)
        
    @http_request_bundler.add(
      label, 
      @url + "/authenticate_provider", 
      :get,
      head: headers,
      query: { provider_id: provider_id }
    ).status!(label)
  end
  
  # Authenticates a RidePilot Customer
  def authenticate_customer    
    label = request_label(:authenticate_customer, customer_id)
        
    @http_request_bundler.add(
      label, 
      @url + "/authenticate_customer", 
      :get,
      head: headers,
      query: { provider_id: provider_id, customer_id: customer_id, customer_token: customer_token }
    ).status!(label)
  end
  
  # Gets an array of RidePilot purpose for the passed service
  def trip_purposes    
    label = request_label(:purposes)
        
    @http_request_bundler.add(
      label, 
      @url + "/trip_purposes", 
      :get,
      head: headers,
      query: { provider_id: provider_id }
    ).response!(label)
  end
  
  # Books the passed trip via RidePilot
  def create_trip
    # Only attempt to create trip if all the necessary pieces are there
    return false unless @itinerary && @trip && @service && @user
    
    label = request_label(:book, trip_id)
    
    @http_request_bundler.add(
      label, 
      @url + "/create_trip", 
      :post,
      head: headers,
      body: body_for_booking(@booking_options).to_json
    ).response!(label)
  end
  
  # Gets the RidePilot trip booking status for a given trip
  def trip_status
    label = request_label(:status, trip_id)
            
    @http_request_bundler.add(
      label, 
      @url + "/trip_status", 
      :get,
      head: headers,
      query: { trip_id: trip_id, customer_id: customer_id, customer_token: customer_token }
    ).response!(label) # Always make fresh calls for status
  end
  
  # Gets the RidePilot trip booking status for a given trip
  def cancel_trip
    label = request_label(:cancel, trip_id)
        
    @http_request_bundler.add(
      label, 
      @url + "/cancel_trip", 
      :delete,
      head: headers,
      query: { trip_id: trip_id, customer_id: customer_id, customer_token: customer_token }
    ).response!(label)
  end
  
  ### HELPER METHODS ###
  
  # Returns an array of question objects for RidePilot booking
  def prebooking_questions
    [
      {
        question: "How many guests will be riding with you?", 
        choices: [0,1,2,3], 
        code: "guests"
      },
      {
        question: "How many attendants will be riding with you?", 
        choices: [0,1,2,3], 
        code: "attendants"
      },
      {
        question: "How many mobility devices will you be bringing?", 
        choices: [0,1,2,3], 
        code: "mobility_devices"
      },
      {
        question: "What is your trip purpose?", 
        choices: (trip_purposes["trip_purposes"] || 
                  Config.ride_pilot_purposes.try(:map) {|k,v| {"name" => k, "code" => v}} || 
                  []).map{|p| [p["name"], p["code"]]}, 
        code: "purpose"
      }
    ]
  end
  
  # Returns the RidePilot Purposes Map from the Configs
  def purposes_map
    (Config.ride_pilot_purposes || {}).with_indifferent_access
  end
  
  # Maps a OneClick Purpose Code to RidePilot Purpose ID. Pass a service to
  # use its RidePilot Purposes list
  def map_purpose_to_ridepilot(occ_purpose)
    purposes_map[occ_purpose.try(:code)]
  end
    
  # Pulls provider_id out of the service's booking details
  def provider_id
    @service.try(:booking_details).try(:[], :provider_id)
  end
  
  # Gets the customer id from the user's booking profile
  def customer_id
    @booking_profile.try(:external_user_id)
  end

  # Gets the customer token from the user's booking profile  
  def customer_token
    @booking_profile.try(:external_password)
  end
  
  # Gets the RidePilot trip_id from the booking object
  def trip_id
    booking.try(:confirmation)
  end
  
  # Builds RidePilot HTTP Request Headers
  def headers
    {
      "X-Ridepilot-Token" => @token,
      "Content-Type" => "application/json"
    }
  end
  
  # Build request body for book (i.e. create_trip) call
  def body_for_booking(opts={})
    attendants = opts[:attendants] || 0
    mobility_devices = opts[:mobility_devices] || 0
    guests = opts[:guests] || 0
    purpose_code = opts[:purpose] || map_purpose_to_ridepilot(@trip.purpose) # Convert trip purpose to RidePilot code
    leg = opts[:return] ? 2 : 1 # outbound or return
    @trip.errors.add(:booking, "Cannot book without trip purpose code.") unless purpose_code
    
    {
      provider_id: @service.booking_details[:provider_id], # Pull from selected itinerary's service's booking profile
    	customer_id: customer_id, # Pull from traveler's booking profile
    	customer_token: customer_token, # Pull from traveler's booking profile
    	trip_purpose: purpose_code, 
    	pickup_time: @itinerary.start_time.iso8601,
    	dropoff_time: @itinerary.end_time.iso8601,
    	attendants: attendants,
      mobility_devices: mobility_devices,
    	guests: guests,
      leg: leg,
    	from_address: { address: @trip.origin.try(:google_place_hash) },
    	to_address: { address: @trip.destination.try(:google_place_hash) }
    }
  end
  
  # returns a hash of booking attributes from a RidePilot response
  def booking_attrs_from_response(response)
    {
      type: "RidePilotBooking",
      details: response.try(:with_indifferent_access),
      status: response.try(:[], "status").try(:[], "code"),
      confirmation: response.try(:[], "trip_id")
    }
  end
  
  # Updates trip booking object with response
  def update_booking(response)
    return false unless response
    booking.try(:update_attributes, booking_attrs_from_response(response))
  end

end
