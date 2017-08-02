class RidePilotAmbassador
  
  attr_accessor :http_request_bundler, :url, :token, :service
  
  # Initialize with a service and an (optional) options hash
  def initialize(service, opts={})
    @service = service
    @url = opts[:url] || Config.ride_pilot_url
    @token = opts[:token] || Config.ride_pilot_token
    @http_request_bundler = opts[:http_request_bundler] || HTTPRequestBundler.new
  end
  
  # Gets an array of RidePilot purpose for the passed service
  def trip_purposes
    provider_id = @service.booking_details.try(:[], :provider_id)
    label = request_label(:purposes, provider_id)
        
    @http_request_bundler.add(
      label, 
      @url + "/trip_purposes", 
      :get,
      head: headers,
      query: { provider_id: provider_id }
    )
    return @http_request_bundler.response(label)
  end
  
  
  # Returns the RidePilot Purposes Map from the Configs
  def purposes_map
    (Config.ridepilot_purposes || {}).with_indifferent_access
  end
  
  # Maps a OneClick Purpose Code to RidePilot Purpose ID. Pass a service to
  # use its RidePilot Purposes list
  def map_purpose_to_ridepilot(occ_purpose)
    purposes_map[occ_purpose.try(:code)]
  end
  
  # Books the passed trip via RidePilot
  def book(trip, opts={})
    
    label = request_label(:book, trip.id)
    
    @http_request_bundler.add(
      label, 
      @url + "/create_trip", 
      :post,
      head: headers,
      body: body_for_booking(trip, opts).to_json
    )
    return @http_request_bundler.response(label)
  end
  
  private
  
  # Makes a symbolic label for HTTP requests, out of an arbitrary # of identifiers
  def request_label(*identifiers)
    (["ridepilot"] + identifiers).join("_").to_sym
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
    	dropoff_time: (trip.trip_time + 1.hour).iso8601, # Pull increment from options
    	attendants: attendants,
    	guests: guests,
    	from_address: { address: trip.origin.try(:google_place_hash) },
    	to_address: { address: trip.destination.try(:google_place_hash) }
    }
  end
  
end
