class RidePilotAmbassador
  
  attr_accessor :http_request_bundler, :url, :token
  
  def initialize(opts={})
    @url = opts[:url] || Config.ride_pilot_url
    @token = opts[:token] || Config.ride_pilot_token
    @http_request_bundler = opts[:http_request_bundler] || HTTPRequestBundler.new
  end
  
  # Gets an array of RidePilot purpose for the passed service
  def get_purposes(service)
    provider_id = service.booking_details.try(:[], :provider_id)
    
    @http_request_bundler.add(
      request_label(:purposes, provider_id), 
      @url + "/trip_purposes", 
      :get,
      head: headers,
      query: { provider_id: provider_id }
    )
    return @http_request_bundler.response(:ridepilot_purposes)
  end
  
  # Books the passed trip via RidePilot
  def book(trip, opts={})
    @http_request_bundler.add(
      :ridepilot_booking, 
      @url + "/create_trip", 
      :post,
      head: headers,
      body: body_for_booking(trip, opts).to_json
    )
    return @http_request_bundler.response(:ridepilot_booking)
  end
  
  private
  
  def request_label(*identifiers)
    (["ridepilot"] + identifiers).join("_").to_sym
  end
  
  def headers
    {
      "X-Ridepilot-Token" => @token,
      "Content-Type" => "application/json"
    }
  end
  
  def body_for_booking(trip, opts={})
    duration = opts[:duration] || 1.hour  # Time to spend at destination
    attendants = opts[:attendants] || 0
    guests = opts[:guests] || 0
    service = trip.selected_itinerary.try(:service)
    traveler = trip.user
    
    {
      provider_id: service.booking_details[:provider_id], # Pull from selected itinerary's service's booking profile
    	customer_id: traveler.booking_profile_for(service).details[:id], # Pull from traveler's booking profile
    	customer_token: traveler.booking_profile_for(service).details[:token], # Pull from traveler's booking profile
    	trip_purpose: 13, # Convert trip purpose to RidePilot code
    	pickup_time: trip.trip_time.iso8601,
    	dropoff_time: (trip.trip_time + 1.hour).iso8601, # Pull increment from options
    	attendants: attendants,
    	guests: guests,
    	from_address: { address: trip.origin.try(:google_place_hash) },
    	to_address: { address: trip.destination.try(:google_place_hash) }
    }
  end
  
end
