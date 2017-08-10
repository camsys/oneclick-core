# All booking ambassadors should implement the following public methods:
  # book() => Booking object
  # cancel() => Booking object
  # status() => Booking object

class RidePilotAmbassador
  
  attr_accessor :http_request_bundler, 
                :url, 
                :token, 
                :booking_options, 
                :itinerary,
                :service, 
                :trip, 
                :user,
                :booking_profile,
                :errors
  
  # Initialize with a service and an (optional) options hash
  def initialize(opts={})
    self.itinerary = opts[:itinerary]
    self.trip = opts[:trip] || @trip
    self.booking_profile = opts[:booking_profile] || @booking_profile
    self.service = opts[:service] || @service
    self.user = opts[:user] || @user # Defaults to trip.user
    
    @url = opts[:url] || Config.ride_pilot_url || ""
    @token = opts[:token] || Config.ride_pilot_token || ""
    @http_request_bundler = opts[:http_request_bundler] || HTTPRequestBundler.new
    @booking_options = opts[:booking_options] || {}
    @errors = []
  end
  
  # Custom setter for itinerary also sets trip, service, and user
  def itinerary=(new_itin)
    @itinerary = new_itin
    return unless @itinerary
    self.trip = @itinerary.try(:trip) || @trip
    self.service = @itinerary.try(:service) || @service
  end
  
  # Custom setter for trip also sets user
  def trip=(new_trip)
    @trip = new_trip
    return unless @trip
    @itinerary = @trip.selected_itinerary || @itinerary
    @user = @trip.try(:user) || @user
  end
  
  # Custom setter for booking_profile also sets user and service
  def booking_profile=(new_booking_profile)
    @booking_profile = new_booking_profile
    return unless @booking_profile
    @user = @booking_profile.try(:user) || @user
    @service = @booking_profile.try(:service) || @service
  end
  
  # Custom setter for user also sets booking profile if not set already
  def user=(new_user)
    @user = new_user
    return unless @user && @service
    @booking_profile ||= @user.try(:booking_profile_for, @service)
  end
  
  
  ### STANDARD BOOKING ACTIONS ###
  # (Implemented by all Booking Ambassadors)

  def book
    # select the itinerary if not already selected
    @itinerary.select if @itinerary && !@itinerary.selected?

    # Make a create_trip call to RidePilot, passing a trip and any 
    # booking_options that have been set
    response = create_trip
    Rails.logger.debug @errors.to_sentence unless @errors.empty?
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
  
  # Returns the trip's Booking, if available. Otherwise, builds a booking object
  def booking
    RidePilotBooking.find_or_initialize_by(itinerary_id: @itinerary.try(:id))
    # booking = @itinerary.try(:booking) || @itinerary.build_booking(type: "RidePilotBooking")
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
    booking_profile.try(:details).try(:[], :id)
  end

  # Gets the customer token from the user's booking profile  
  def customer_token
    booking_profile.try(:details).try(:[], :token)
  end
  
  # Gets the RidePilot trip_id from the booking object
  def trip_id
    booking.try(:confirmation)
  end
  
  # Makes a symbolic label for HTTP requests, out of an arbitrary # of identifiers
  # Appends service's RidePilot provider_id to the label
  def request_label(*identifiers)
    (["ridepilot"] + identifiers + [provider_id]).join("_").to_sym
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
    # dropoff_time = (opts[:return_time].try(:to_datetime) || 
    #                 @trip.trip_time + 1.hour)  # Time to spend at destination
    attendants = opts[:attendants] || 0
    mobility_devices = opts[:mobility_devices] || 0
    guests = opts[:guests] || 0
    purpose_code = opts[:purpose] || map_purpose_to_ridepilot(@trip.purpose) # Convert trip purpose to RidePilot code
    @errors << "Cannot book without trip purpose code." unless purpose_code
    
    {
      provider_id: @service.booking_details[:provider_id], # Pull from selected itinerary's service's booking profile
    	customer_id: @user.booking_profile_for(@service).details[:id], # Pull from traveler's booking profile
    	customer_token: @user.booking_profile_for(@service).details[:token], # Pull from traveler's booking profile
    	trip_purpose: purpose_code, 
    	pickup_time: @itinerary.start_time.iso8601,
    	dropoff_time: @itinerary.end_time.iso8601,
    	attendants: attendants,
      mobility_devices: mobility_devices,
    	guests: guests,
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
  
  # Select's the trip's itinerary associated with @service
  def ensure_selected_itinerary
    # Find the appropriate itinerary based on service_id
    itin_to_book = @itinerary || @trip.itineraries.find_by(service_id: @service.id)

    # Select the itinerary and return true, or return false if no appropriate itinerary exists
    if itin_to_book.present?
      itin_to_book.select
      return true
    else
      return false
    end
    
  end
  
  # Updates trip booking object with response
  def update_booking(response)
    return false unless response
    booking.try(:update_attributes, booking_attrs_from_response(response))
  end

end
