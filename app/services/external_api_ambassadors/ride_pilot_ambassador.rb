# All booking ambassadors should implement the following public methods:
  # book(trip) => Booking object
  # cancel(trip) => Booking object
  # status(trip) => Booking object
  # prepare_to_book(options={})

class RidePilotAmbassador
  
  attr_accessor :http_request_bundler, :url, :token, :service, :booking_options
  
  
  # Initialize with a service and an (optional) options hash
  def initialize(service, opts={})
    @service = service
    @url = opts[:url] || Config.ride_pilot_url
    @token = opts[:token] || Config.ride_pilot_token
    @http_request_bundler = opts[:http_request_bundler] || HTTPRequestBundler.new
    @booking_options = opts[:booking_options] || {}
  end
  
  ### STANDARD BOOKING ACTIONS ###
  # (Implemented by all Booking Ambassadors)

  def book(trip)
    # Make a create_trip call to RidePilot, passing a trip and any 
    # booking_options that have been set
    response = create_trip(trip)
    
    # Store the status info in a Booking object and return it
    booking = trip.build_booking(booking_attrs_from_response(response))
    booking.save
    return booking
  end
  
  def cancel(trip)
  end
  
  def status(trip)
    # Make a get_status call to RidePilot, passing a trip
    response = trip_status(trip)
    
    # Update Booking object with status info and return it
    booking = trip.booking || trip.build_booking
    return false unless booking # Return false if trip has no booking even after building (e.g. because no itinerary is selected)
    booking.assign_attributes(booking_attrs_from_response(response))
    booking.save
    return booking.try(:status)
  end
  
  def prepare_to_book(options={})
    @booking_options = options
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
    )
    return @http_request_bundler.success?(label)
  end
  
  # Authenticates a RidePilot Customer
  def authenticate_customer(user)
    label = request_label(:authenticate_customer, user.id)
    booking_profile = user.booking_profile_for(@service)
    return false unless booking_profile
        
    @http_request_bundler.add(
      label, 
      @url + "/authenticate_customer", 
      :get,
      head: headers,
      query: {  provider_id: provider_id,
                customer_id: booking_profile.details[:id],
                customer_token: booking_profile.details[:token] }
    )
    return @http_request_bundler.success?(label)
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
    )
    return @http_request_bundler.response(label)
  end
  
  # Books the passed trip via RidePilot
  def create_trip(trip)    
    label = request_label(:book, trip.id)
    
    @http_request_bundler.add(
      label, 
      @url + "/create_trip", 
      :post,
      head: headers,
      body: body_for_booking(trip, @booking_options).to_json
    )
    return @http_request_bundler.response(label)
  end
  
  # Gets the RidePilot trip booking status for a given trip
  def trip_status(trip)
    label = request_label(:status, trip.id)
    user = trip.user
    booking_profile = user.try(:booking_profile_for, @service)
    trip_booking = trip.booking
    return false unless booking_profile
            
    @http_request_bundler.add(
      label, 
      @url + "/trip_status", 
      :get,
      head: headers,
      query: {  trip_id: trip_booking.try(:details).try(:[], :trip_id),
                customer_id: booking_profile.details[:id],
                customer_token: booking_profile.details[:token] }
    )
    return @http_request_bundler.response(label)
  end
  
  # Gets the RidePilot trip booking status for a given trip
  def cancel_trip(trip)
    label = request_label(:status, trip.id)
    user = trip.user
    booking_profile = user.try(:booking_profile_for, @service)
    trip_booking = trip.booking
    return false unless booking_profile
        
    @http_request_bundler.add(
      label, 
      @url + "/cancel_trip", 
      :delete,
      head: headers,
      query: {  trip_id: trip_booking.try(:details).try(:[], :trip_id),
                customer_id: booking_profile.details[:id],
                customer_token: booking_profile.details[:token] }
    )
    return @http_request_bundler.response(label)
  end
  
  ### HELPER METHODS ###
  
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
    @service.booking_details.try(:[], :provider_id)
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
  def body_for_booking(trip, opts={})
    duration = opts[:duration] || 1.hour  # Time to spend at destination
    attendants = opts[:attendants] || 0
    guests = opts[:guests] || 0
    traveler = trip.user
    
    {
      provider_id: @service.booking_details[:provider_id], # Pull from selected itinerary's service's booking profile
    	customer_id: traveler.booking_profile_for(@service).details[:id], # Pull from traveler's booking profile
    	customer_token: traveler.booking_profile_for(@service).details[:token], # Pull from traveler's booking profile
    	trip_purpose: map_purpose_to_ridepilot(trip.purpose), # Convert trip purpose to RidePilot code
    	pickup_time: trip.trip_time.iso8601,
    	dropoff_time: (trip.trip_time + duration).iso8601, # Pull increment from options
    	attendants: attendants,
    	guests: guests,
    	from_address: { address: trip.origin.try(:google_place_hash) },
    	to_address: { address: trip.destination.try(:google_place_hash) }
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
  
end
