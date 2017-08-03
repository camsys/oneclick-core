# All booking ambassadors should implement the following public methods:
  # book(trip) => Booking object
  # cancel(trip) => Booking object
  # status(trip) => Booking object

class RidePilotAmbassador
  
  attr_accessor :http_request_bundler, 
                :url, 
                :token, 
                :booking_options, 
                :service, 
                :trip, 
                :user
  
  
  # Initialize with a service and an (optional) options hash
  def initialize(opts={})
    @service = opts[:service]
    @trip = opts[:trip]
    @user = opts[:user] || @trip.try(:user) # Defaults to trip.user
    @url = opts[:url] || Config.ride_pilot_url
    @token = opts[:token] || Config.ride_pilot_token
    @http_request_bundler = opts[:http_request_bundler] || HTTPRequestBundler.new
    @booking_options = opts[:booking_options] || {}
  end
  
  # Custom setter for trip also sets user
  def trip=(new_trip)
    @trip = new_trip
    @user = @trip.try(:user) || @user
  end
  
  
  ### STANDARD BOOKING ACTIONS ###
  # (Implemented by all Booking Ambassadors)

  def book
    # Make a create_trip call to RidePilot, passing a trip and any 
    # booking_options that have been set
    response = create_trip
    return false unless response
    
    # Store the status info in a Booking object and return it
    @trip.build_booking unless trip_booking
    update_trip_booking(response)
    return trip_booking
  end
  
  def cancel
    # Make a cancel_trip call to RidePilot, using @trip
    response = cancel_trip
    return false unless response
    
    update_trip_booking(response)
    return trip_booking.try(:status)
  end
  
  def status
    # Make a get_status call to RidePilot, using @trip
    response = trip_status
    return false unless response
    
    # Update Booking object with status info and return it
    # return false unless booking # Return false if trip has no booking even after building (e.g. because no itinerary is selected)
    # booking.assign_attributes(booking_attrs_from_response(response))
    # booking.save
    update_trip_booking(response)
    return trip_booking.try(:status)
  end


  ### API CALLS ###
  
  # Authenticates a RidePilot Provider
  def authenticate_provider
    return false unless @service
    
    label = request_label(:authenticate_provider)
        
    @http_request_bundler.add(
      label, 
      @url + "/authenticate_provider", 
      :get,
      head: headers,
      query: { provider_id: provider_id }
    ).call!(label).success?(label)
  end
  
  # Authenticates a RidePilot Customer
  def authenticate_customer
    return false unless @user && @service && booking_profile
    
    label = request_label(:authenticate_customer, @user.id)
        
    @http_request_bundler.add(
      label, 
      @url + "/authenticate_customer", 
      :get,
      head: headers,
      query: {  provider_id: provider_id,
                customer_id: booking_profile.details[:id],
                customer_token: booking_profile.details[:token] }
    ).call!(label).success?(label)
  end
  
  # Gets an array of RidePilot purpose for the passed service
  def trip_purposes
    return false unless @service
    
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
    return false unless @trip && @service && @user
    
    label = request_label(:book, @trip.id)
    
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
    return false unless @trip && @user && booking_profile && trip_booking
    label = request_label(:status, @trip.id)
            
    @http_request_bundler.add(
      label, 
      @url + "/trip_status", 
      :get,
      head: headers,
      query: {  trip_id: trip_booking.try(:details).try(:[], :trip_id),
                customer_id: booking_profile.details[:id],
                customer_token: booking_profile.details[:token] }
    ).response!(label) # Always make fresh calls for status
  end
  
  # Gets the RidePilot trip booking status for a given trip
  def cancel_trip
    return false unless @trip && @user && booking_profile && trip_booking
    label = request_label(:cancel, trip.id)
        
    @http_request_bundler.add(
      label, 
      @url + "/cancel_trip", 
      :delete,
      head: headers,
      query: {  trip_id: trip_booking.try(:details).try(:[], :trip_id),
                customer_id: booking_profile.details[:id],
                customer_token: booking_profile.details[:token] }
    ).response!(label)
  end
  
  ### HELPER METHODS ###
  
  # Returns the user's booking profile if available
  def booking_profile
    @user.try(:booking_profile_for, @service)
  end
  
  # Returns the trip's Booking, if available
  def trip_booking
    @trip.try(:booking)
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
    duration = opts[:duration] || 1.hour  # Time to spend at destination
    attendants = opts[:attendants] || 0
    guests = opts[:guests] || 0
    
    {
      provider_id: @service.booking_details[:provider_id], # Pull from selected itinerary's service's booking profile
    	customer_id: @user.booking_profile_for(@service).details[:id], # Pull from traveler's booking profile
    	customer_token: @user.booking_profile_for(@service).details[:token], # Pull from traveler's booking profile
    	trip_purpose: map_purpose_to_ridepilot(@trip.purpose), # Convert trip purpose to RidePilot code
    	pickup_time: @trip.trip_time.iso8601,
    	dropoff_time: (@trip.trip_time + duration).iso8601, # Pull increment from options
    	attendants: attendants,
    	guests: guests,
    	from_address: { address: @trip.origin.try(:google_place_hash) },
    	to_address: { address: @trip.destination.try(:google_place_hash) }
    }
  end
  
  # returns a hash of booking attributes from a RidePilot response
  def booking_attrs_from_response(response)
    {
      type: "RidePilotBooking",
      details: response.with_indifferent_access,
      status: response.try(:[], "status").try(:[], "code")
    }
  end
  
  # Select's the trip's itinerary associated with @service
  def ensure_selected_itinerary
    # Find the appropriate itinerary based on service_id
    itin_to_book = @trip.itineraries.find_by(service_id: @service.id)

    # Select the itinerary and return true, or return false if no appropriate itinerary exists
    if itin_to_book.present?
      itin_to_book.select
      return true
    else
      return false
    end
    
  end
  
  # Updates trip booking object with response
  def update_trip_booking(response)
    return false unless trip_booking
    trip_booking.update_attributes(booking_attrs_from_response(response))
  end
  
end
