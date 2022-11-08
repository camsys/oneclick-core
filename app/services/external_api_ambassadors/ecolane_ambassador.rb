class EcolaneAmbassador < BookingAmbassador

  attr_accessor :customer_number, :service, :confirmation, :system_id, :token, :trip, :customer_id, :guest_funding_sources, :dummy
  require 'securerandom'

  def initialize(opts={})
    #TODO Clean up this mess
    super(opts)
    @url ||= Config.ecolane_url
    @county = opts[:county]
    @dob = opts[:dob]
    self.trip = opts[:trip] if opts[:trip]
    self.service = opts[:service] if opts[:service]
    @customer_number = opts[:ecolane_id] #This is what the customer knows
    @customer_id = nil #This is how Ecolane identifies the customer. This is set by get_user.
    @service ||= county_map[@county]
    self.system_id ||= @service.booking_details[:external_id]
    self.token = @service.booking_details[:token]
    @user ||= @trip.nil? ? (@customer_number.nil? ? nil : get_user) : @trip.user
    @purpose = @trip.external_purpose unless @trip.nil?
    get_booking_profile
    check_travelers_transit_agency
    add_missing_attributes
    
    # Funding Rules Shortcuts
    @preferred_funding_sources = @service.booking_details.try(:[], :preferred_funding_sources).split(',').map{ |x| x.strip }
    @preferred_sponsors =  @service.booking_details.try(:[], :preferred_sponsors).split(',').map{ |x| x.strip } + [nil]
    @ada_funding_sources = @service.booking_details.try(:[], :ada_funding_sources).split(',').map{ |x| x.strip } + [nil]
    @dummy = @service.booking_details.try(:[], :dummy_user)
    @guest_funding_sources = @service.booking_details.try(:[], :guest_funding_sources)
    if @guest_funding_sources
      @guest_funding_sources = @guest_funding_sources.split("\r\n").map {
        |x| {code: x.split(',').first.strip, desc: x.split(',').last.strip}
      }
    else
      puts '*** no guest funding sources ***'
      @guest_funding_sources = []
    end
    @guest_purpose = @service.booking_details.try(:[], :guest_purpose)

    @booking_options = opts[:booking_options]
    @use_ecolane_rules = @service.booking_details["use_ecolane_funding_rules"].to_bool
  end

  #####################################################################
  ## Custom Setters
  #####################################################################

  def itinerary=(new_itin)
    @itinerary = new_itin
    return unless @itinerary
    self.trip = @itinerary.try(:trip) || @trip #TODO Use @trip everywhere. 
    self.service = @itinerary.try(:service) || @service
  end

  def service=(this_service)
    @service = this_service
  end

  def get_booking_profile
    return if @booking_profile 
    if @service and @user 
      @booking_profile = UserBookingProfile.find_by(service: @service, user: @user)
    end
  end

  def check_travelers_transit_agency
    # If @user is not present, return
    return unless @user.present? && @booking_profile.present?

    # if user is a user but has no traveler transit agency
    #   make one with the user booking profile
    # if the user has a traveler transit agency but agency is nil
    #   check booking profile for the service's agency and populate with that
    if @user.traveler_transit_agency.nil?
      ag = @booking_profile.service.agency
      TravelerTransitAgency.find_or_create_by(user_id: @user.id, transportation_agency_id: ag.id)
    elsif @user.traveler_transit_agency.transportation_agency.nil? && @booking_profile.present?
      @user.traveler_transit_agency.transportation_agency = @booking_profile.service.agency
    end
  end

  def add_missing_attributes
    return unless @user and @booking_profile
    @customer_number ||= @booking_profile.external_user_id
    @customer_id ||= @booking_profile.details[:customer_id]
    @confirmation ||= booking.confirmation
  end

  #####################################################################
  ## Top-level required methods in order for BookingAmbassador to work
  #####################################################################
  # Returns symbol for identifying booking api type
  def booking_api
    :ecolane
  end

  def authentic_provider?
    true
  end

  # Get all future trips and trips within the past month 
  # Create 1-Click Trips for those trips if they don't already exist
  def sync days_ago=1

    #For performance, only update trips in the future
    options = {
      start: (Time.current - days_ago.day).iso8601[0...-6]
    }

    (arrayify(fetch_customer_orders(options).try(:with_indifferent_access).try(:[], :orders).try(:[], :order))).each do |order|
      occ_trip_from_ecolane_trip order
    end

    # For trips that are round trips, make sure that they point to each other.
    link_trips

  end

    # Books Trip (funding_source and sponsor must be specified)
  def book
    booking = new_order
    sync
    booking
  end

  def cancel
    # Don't ever allow cancellations within 1 hour
    if @itinerary.booking and @itinerary.booking.negotiated_pu and (@itinerary.booking.negotiated_pu - Time.now) < 3600
      return @itinerary.booking
    end
    @itinerary.booking.reload
    result = cancel_order
    # Unselect the itinerary on successful cancellation
    @itinerary.unselect if result
    # Update Booking object with status info and return it
    new_status = status @itinerary.booking.confirmation 
    @itinerary.booking.update({status: new_status})
    @itinerary.booking
  end

  def prebooking_questions
    funding_source = self.booking.details.try(:with_indifferent_access).try(:[],:funding_hash).try(:[],:funding_source)
    if funding_source.in? @ada_funding_sources
      questions =
        [
          {question: "Will you be traveling with an ADA-approved escort?", choices: [true, false], code: "assistant"},
          {question: "How many other companions are traveling with you?", choices: (0..10).to_a, code: "companions"}
        ]
    else
      questions =
        [
          {question: "Will you be traveling with an approved escort?", choices: [true, false], code: "assistant"},
          {question: "How many children or family members will be traveling with you?", choices: (0..2).to_a, code: "children"}
        ]
    end
    questions
  end

  ####################################################################
  ## Actual Calls to Ecolane 
  ####################################################################

  def new_order
    url_options = "/api/order/#{system_id}?overlaps=reject"
    url = @url + url_options
    begin
      order =  build_order
      resp = send_request(url, 'POST', order)
    # NOTE: this seems like overkill, but Ecolane uses both JSON and
    # ...XML for their responses, and failed responses are formatted as JSON
      body_hash = Hash.from_xml(resp.body)
      if body_hash.try(:with_indifferent_access).try(:[], :status).try(:[], :result) == "success"
        confirmation = Hash.from_xml(resp.body).try(:with_indifferent_access).try(:[], :status).try(:[], :success).try(:[], :resource_id)
        eco_trip  = fetch_order(confirmation)["order"]
        booking = self.booking
        booking.update(occ_booking_hash(eco_trip))
        booking.itinerary = itinerary
        booking.confirmation = confirmation
        booking.created_in_1click = true
        booking.save
        booking
      else
        @trip.update(disposition_status: Trip::DISPOSITION_STATUSES[:ecolane_denied])
        nil
      end
    rescue REXML::ParseException
      @trip.update(disposition_status: Trip::DISPOSITION_STATUSES[:ecolane_denied])
      nil
    end
  end

  # Get a list of customers
  def search_for_customers terms={}
    url_options = "/api/customer/#{system_id}/search?"
    terms.each do |key,value|
      url_options += "&#{key}=#{value}"
    end
    resp = send_request(@url+url_options)
    Hash.from_xml(resp.body)
  end

  # Get orders for a customer
  def fetch_customer_orders options={}
    url_options = "/api/customer/#{system_id}/"
    url_options += @customer_id.to_s
    url_options += "/orders"
    url_options += ("/?" + options.map{|k,v| "#{k}=#{v}"}.join("&"))
    resp = send_request(@url + url_options, token)
    begin
      Hash.from_xml(resp.body)
    rescue REXML::ParseException => e
      pp e
      {}
    end
  end

  # Get Single Order
  def fetch_order confirmation=@confirmation
    url_options = "/api/order/#{system_id}/#{confirmation}"
    resp = send_request(@url + url_options, token)
    # NOTE: this seems like overkill, but Ecolane uses both JSON and
    # ...XML for their responses, and failed responses are formatted as JSON
    begin
      Hash.from_xml(resp.body)
    rescue REXML::ParseException => e
      {}
    end
  end

  # Get customer information from ID
  # If funding=true, return funding_info
  # If locations=true return a list of the clients locations (e.g., home)
  def fetch_customer_information(funding=false,locations=false) 
    url_options = "/api/customer/#{system_id}/"
    url_options += @customer_id.to_s
    url_options += "?funding=" + funding.to_s + "&locations=" + locations.to_s
    url = @url + url_options
    t = Time.current
    resp = send_request(url, token )
    Hash.from_xml(resp.body)
  end

  # Get all the Ecolane POIS
  def fetch_system_poi_list
    url_options = "/api/location/#{system_id}/pois"
    url = @url + url_options
    resp = send_request(url, token )

    begin
      resp_code = resp.code
      body = Hash.from_xml(resp.body)
    rescue
      return nil
    end

    if resp_code == "200"
      body["locations"]["location"]
    else
      nil
    end
  end

  # Cancel a Trip
  def cancel_order 
    unless @confirmation
      Rails.logger.debug "Unable to cancel itinerary #{itinerary.id} because no confirmation number is present in the booking."
      return false
    end

    url_options = "/api/order/#{system_id}/#{@confirmation}"
    url = @url + url_options
    resp = send_request(url, 'DELETE')

    begin
      resp_code = resp.code
    rescue
      return false
    end

    if resp_code == "200"
      Rails.logger.debug "Trip #{@confirmation} canceled."
      #The trip was successfully canceled
      true
    elsif status == 'canceled'
      Rails.logger.debug "Trip #{@confirmation}  already canceled."
      #The trip was not successfully deleted, because it was already canceled
      return true
    else
      Rails.logger.debug "Trip #{@confirmation}  cannot be canceled."
      #The trip is not canceled
      false
    end

  end

  def get_ecolane_fare
    build_ecolane_funding_hash[0]
  end

  def get_1click_fare funding_hash=nil
    url_options =  "/api/order/#{system_id}/queryfare"
    url = @url + url_options
    
    if funding_hash
      order = build_order(true, funding_hash)
    else
      order = build_order 
    end
    # err on new qa is response didn't finish building
    resp = send_request(url, 'POST', order)
    return nil if resp.code != "200"
    resp = Hash.from_xml(resp.body)
    resp.try(:with_indifferent_access).try(:[],:fare).try(:[],:client_copay).to_f/100 
  end

  # Find the fare for a trip.
  def get_fare
    return unless @customer_id #If there is no user, then just return nil
    if @use_ecolane_rules #use Ecolane Rules
      get_ecolane_fare
    else
      get_1click_fare
    end
  end

    # Checks on an itineraries funding options and sends the request to Ecolane
  def get_funding_options
    url_options = "/api/order/#{system_id}/queryfunding"
    url = @url + url_options
    order =  build_order(funding=false)
    resp = Hash.from_xml(send_request(url, 'POST', order).body)
    resp.try(:with_indifferent_access).try(:[], :funding_options).try(:[], :option)
  end

  def get_funding_hash
    #TODO: Reduce call to Ecolane by saving the funding_hash after the first time we ask for it.
    if @service.booking_details["use_ecolane_funding_rules"].to_bool #use Ecolane Rules
      fare, funding_hash = build_ecolane_funding_hash
    else #use 1-Click Rules
      funding_hash = build_1click_funding_hash
    end
    if self.booking
      booking = self.booking 
      if booking.details 
        booking.details[:funding_hash] = funding_hash
      else
        booking.details = {funding_hash: funding_hash}
      end
      booking.save 
    end
    funding_hash
  end


  ##### 
  ## Send the Requests
  def send_request url, type='get', message=nil

    if message 
      message = Nokogiri::XML(message).to_s
    end

    url.sub! " ", "%20"
    begin
      uri = URI.parse(url)
      case type.downcase
        when 'post'
          req = Net::HTTP::Post.new(uri.path)
          req.body = message
        when 'delete'
          req = Net::HTTP::Delete.new(uri.path)
        else
          req = Net::HTTP::Get.new(uri)
      end

      req.add_field 'X-ECOLANE-TOKEN', token
      req.add_field 'Content-Type', 'text/xml'

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      Rails.logger.info '----------Calling Ecolane-----------'
      Rails.logger.info "#{type}: #{url}"
      Rails.logger.info "X-ECOLANE-TOKEN: #{token}"
      Rails.logger.info Hash.from_xml(message)
      resp = http.start {|http| http.request(req)}
      Rails.logger.info '------Response from Ecolane---------'
      Rails.logger.info "Code: #{resp.code}"
      # TODO: Figure out how to get only JSON or only XML responses for Ecolane
      Rails.logger.info resp.body
      return resp
    rescue Exception=>e
      Rails.logger.info("Sending Error")
      return false, {'id'=>500, 'msg'=>e.to_s}
    end
  end

  ###################################################################
  ## Helpers
  ###################################################################

  # Get the current balance in dollars for a customer or nil if unavailable
  def get_current_balance
    customer_information = fetch_customer_information(funding=true)
    # Convert cents to dollars
    balance = customer_information["customer"]["balance"].to_f / 100.0
    balance
  end


  # Get a list of trip purposes for a customer
  def get_trip_purposes 
    purposes = []
    purposes_hash = []
    customer_information = fetch_customer_information(funding=true)
    arrayify(customer_information["customer"]["funding"]["funding_source"]).each do |funding_source|
      if not @use_ecolane_rules and not funding_source["name"].in? @preferred_funding_sources
        next 
      end
      arrayify(funding_source["allowed"]).each do |allowed|
        purpose = allowed["purpose"]
        # Add the date range for which the purpose is eligible, if available.
        purpose_hash = {code: allowed["purpose"], valid_from: funding_source["valid_from"], valid_until: funding_source["valid_until"]}
        unless purpose.in? purposes #or purpose.downcase.strip.in? (disallowed_purposes.map { |p| p.downcase.strip } || "")
          purposes.append(purpose)
        end
        purposes_hash << purpose_hash
      end
    end
    banned_purposes = @service.booking_details[:banned_purposes]
    purposes = purposes.sort.uniq - (banned_purposes.blank? ? [] : banned_purposes.split(',').map{ |x| x.strip })
    [purposes, purposes_hash]
  end

  # Get a list of all the points of interest for the service
  def get_pois
      locations = fetch_system_poi_list
      if locations.nil?
        return nil
      end

      # Convert the Ecolane Locations to a Hash that Matches 1-Click Schema
      hashes = []
      locations.each do |location|
        hashes << {name: location["name"].to_s.strip, city: location["city"].to_s.strip, state: location["state"].to_s.strip, zip: location["postcode"].to_s.strip, lat: location["latitude"], lng: location["longitude"], county: location["county"].to_s.strip, street_number: location["street_number"].to_s.strip, route: location["street"].to_s.strip}
      end
      hashes
  end

  # Lookup Customer Number from DOB (YYYY-MM-DD) and Last Name
  def lookup_customer_number params
    customers = arrayify(search_for_customers(params).try(:with_indifferent_access).try(:[], :search_results).try(:[], :customer))
    return customers.length == 1 ? customers.first.try(:[], :customer_number) : nil
  end
  
  ### Create OCC Trip from Ecolane Trip ###
  def occ_trip_from_ecolane_trip eco_trip
    booking_id = eco_trip.try(:with_indifferent_access).try(:[], :id)
    itinerary = @user.itineraries.joins(:booking).find_by('bookings.confirmation = ? AND service_id = ?', booking_id, @service.id)

    if eco_trip.try(:with_indifferent_access).try(:[], :status) == "canceled" and itinerary and not itinerary.selected?
      return 
    end

    # This Trip has already been created, just update it with new times/status etc.
    if itinerary
      booking = itinerary.booking 
      booking.update(occ_booking_hash(eco_trip))
      if booking.status == "canceled"
        trip = itinerary.trip 
        trip.selected_itinerary = nil
        trip.save
        # For some reason itinerary.unselect doesn't work here.
      end
      booking.save
      itinerary.update!(occ_itinerary_hash_from_eco_trip(eco_trip))
      nil
    # This Trip needs to be added to OCC
    else
      # Make the Trip
      trip = Trip.create!(occ_trip_hash(eco_trip))
      # Make the Itinerary
      itinerary = Itinerary.new(occ_itinerary_hash_from_eco_trip(eco_trip))
      itinerary.trip = trip
      itinerary.save 
      itinerary.select

      # Make the Booking
      booking = Booking.new(occ_booking_hash(eco_trip))
      booking.itinerary = itinerary
      if booking.status == 'canceled'
        itinerary.unselect
      end
      booking.save 
    end
  end

  def occ_place_from_eco_place eco_place
    Waypoint.create!(occ_place_hash(eco_place))
  end

  #HASHES
  def occ_trip_hash eco_trip
    origin = occ_place_from_eco_place(eco_trip.try(:with_indifferent_access).try(:[], :pickup).try(:[], :location))
    origin_negotiated = eco_trip.try(:with_indifferent_access).try(:[], :pickup).try(:[], :negotiated)
    destination = occ_place_from_eco_place(eco_trip.try(:with_indifferent_access).try(:[], :dropoff).try(:[], :location))
    destination_requested = eco_trip.try(:with_indifferent_access).try(:[], :dropoff).try(:[], :requested)
    arrive_by = (not destination_requested.nil?)
    # Save the trip_time in the database as UTC time for UTC data type.
    trip_time = origin_negotiated
    {user: @user, origin: origin, destination: destination, trip_time: trip_time, arrive_by: arrive_by}
  end

  def occ_place_hash eco_place
    {
      name:           eco_place.try(:with_indifferent_access).try(:[], :name),
      street_number:  eco_place.try(:with_indifferent_access).try(:[], :street_number),
      route:          eco_place.try(:with_indifferent_access).try(:[], :street),
      city:           eco_place.try(:with_indifferent_access).try(:[], :city),
      zip:            eco_place.try(:with_indifferent_access).try(:[], :postcode),
      lat:            eco_place.try(:with_indifferent_access).try(:[], :latitude),
      lng:            eco_place.try(:with_indifferent_access).try(:[], :longitude),
      county:         eco_place.try(:with_indifferent_access).try(:[], :county)
    }
  end 

  def occ_itinerary_hash_from_eco_trip eco_trip
    origin_negotiated = eco_trip.try(:with_indifferent_access).try(:[], :pickup).try(:[], :negotiated)
    destination_negotiated = eco_trip.try(:with_indifferent_access).try(:[], :dropoff).try(:[], :negotiated)
    destination_requested = eco_trip.try(:with_indifferent_access).try(:[], :dropoff).try(:[], :requested)
    fare = eco_trip.try(:with_indifferent_access).try(:[], :fare).try(:[], :client_copay).to_f/100

    start_time = origin_negotiated.try(:to_time)
    end_time = destination_negotiated.try(:to_time)
    {
      start_time: start_time, 
      end_time: end_time,
      transit_time: (start_time and end_time) ? (end_time - start_time).to_i : nil,
      cost: fare.to_f, 
      service: @service, 
      trip_type: 'paratransit'
    }
  end

  def occ_booking_hash eco_trip 
    negotiated_pu = eco_trip.try(:with_indifferent_access).try(:[], :pickup).try(:[],:negotiated)
    earliest_pu = nil 
    latest_pu = nil 

    if negotiated_pu
      earliest_pu = negotiated_pu.in_time_zone - 15.minutes
      latest_pu = negotiated_pu.in_time_zone + 15.minutes 
    end

    {
      confirmation: eco_trip.try(:with_indifferent_access).try(:[], :id), 
      type: "EcolaneBooking", 
      status: eco_trip.try(:with_indifferent_access).try(:[], :status),
      negotiated_pu: negotiated_pu,
      negotiated_do: eco_trip.try(:with_indifferent_access).try(:[], :dropoff).try(:[],:negotiated),
      estimated_pu: eco_trip.try(:with_indifferent_access).try(:[], :pickup).try(:[],:estimated),
      estimated_do: eco_trip.try(:with_indifferent_access).try(:[], :dropoff).try(:[],:estimated),
      earliest_pu: earliest_pu,
      latest_pu: latest_pu
    }

  end


  ### Does the ID/County/DOB match a single customer?
  def validate_passenger #customer_number, dob, system_id, token

    
    if service.booking_details[:banned_users] and @customer_number.in? service.booking_details.try(:[], :banned_users).split(',').map{ |x| x.strip }
      return false, {}
    end

    iso_dob = iso8601ify(@dob)
    if iso_dob.nil?
      return false, {}
    end
    result = search_for_customers({"date_of_birth": iso_dob, "customer_number": @customer_number})
    if result["search_results"].nil?
      false
    # If only one thing is returned, it comes as a hash.  Multilple items are returned as an array.
    # Since we want to see exactly 1 match, return true if this is a Hash and the account is enabled.
    elsif result["search_results"]["customer"].is_a? Hash
      customer = result["search_results"]["customer"]

      #First make sure that we are setup for self servce
      if (service.booking_details["require_selfservice_validation"].to_bool) and not (customer["status"] and customer["status"]["validated_for"] == "selfservice")
        return false, {note: "Ineligible for online booking"} 
      end

      #if  customer["status"] and customer["status"]["state"] == "enabled"
        return true, customer
      #else
      #  return false, customer
      #end
    else
      [false, {}]
    end
  end

  ### Get a Trip Status ###
  def status confirmation=@confirmation
    fetch_order(confirmation).try(:with_indifferent_access).try(:[], :order).try(:[], :status)
  end


  ### Find or Create User
  def get_user
    valid_passenger, passenger = validate_passenger
    if valid_passenger
      user = nil
      @booking_profile = UserBookingProfile.where(service: @service, external_user_id: @customer_number).first_or_create do |profile|
        random = SecureRandom.hex(8)
        email = @customer_number.gsub(' ', '_')
        user = User.create!(
            email: "#{email}_#{@county}@ecolane_user.com", 
            password: random, 
            password_confirmation: random,            
          )
        profile.details = {customer_id: passenger["id"]}
        profile.booking_api = "ecolane"
        profile.user = user
        # do not try to sync user here - reenters ecolane_ambassador ctor
      end

      # Update the user's name
      user = @booking_profile.user 
      user.first_name = passenger["first_name"]
      user.last_name = passenger["last_name"]     
      user.save

      user
    else
      nil
    end
  end

  def build_order funding=true, funding_hash=nil
    order_hash = {
        assistant: yes_or_no(@booking_options.try(:with_indifferent_access).try(:[], :escort)), 
        companions: @booking_options.try(:with_indifferent_access).try(:[], :companions) || 0, 
        children: @booking_options.try(:with_indifferent_access).try(:[], :children) || 0, 
        other_passengers: 0,
        pickup: build_pu_hash,
        dropoff: build_do_hash}

    unless @customer_id.blank? && @dummy.blank?
      order_hash[:customer_id] = @customer_id || @dummy
    end
    begin
      if funding_hash
        order_hash[:funding] = funding_hash
      elsif funding
        order_hash[:funding] = get_funding_hash
      elsif @purpose
        order_hash[:funding] = {purpose: @purpose}
      end

      order_hash.to_xml(root: 'order', :dasherize => false)
    rescue REXML::ParseException
      nil
    end
  end

  #Build the hash for the pickup request
  def build_pu_hash
    if !trip.arrive_by
      pu_hash = {requested: trip.trip_time.xmlschema[0..-7], location: build_location_hash(trip.origin), note: @note}
    else
      pu_hash = {location: build_location_hash(trip.origin), note: @note}
    end
    pu_hash
  end

  #Build the hash for the drop off request
  def build_do_hash
    if !trip.arrive_by
      do_hash = {location: build_location_hash(trip.destination)}
    else
      do_hash = {requested: trip.trip_time.xmlschema[0..-7], location: build_location_hash(trip.destination)}
    end
    do_hash
  end

  #Build a location hash (Used for dropoffs and pickups )
  def build_location_hash place 
    if !place.name.empty? and !place.name.include?("POI") and place.name.include?("|")
      # Pass name parameter from Ecolane named landmark for better match
      lo_hash = {name: place.name, street_number: place.street_number, street: place.route, city: place.city, 
      state: place.state || "PA", county: (place.county || "").chomp(" County"), zip: place.zip, latitude: place.lat, longitude: place.lng}
    else  
      lo_hash = {street_number: place.street_number, street: place.route, city: place.city, 
      state: place.state || "PA", county: (place.county || "").chomp(" County"), zip: place.zip, latitude: place.lat, longitude: place.lng}
    end
    lo_hash
  end

  ### County Mapping ###
  def county_map
    services = Service.is_ecolane.published
    mapping = {}
    services.each do |service|
      counties = service.booking_details[:home_counties].split(',').map{ |c| c.strip }
      counties.each do |county|
        mapping[county] = service
      end
    end
    mapping
  end

  ### Return array of unique funding source names from the trip's matching travel patterns.
  ### Returns an empty array if no matches found.
  def get_travel_pattern_funding_sources
    travel_pattern_funding_sources = []

    agency = @user&.traveler_transit_agency&.transportation_agency
    if agency.nil?
      return travel_pattern_funding_sources
    end

    travel_pattern_query = TravelPattern.where(agency: agency)
    Rails.logger.info("Getting Travel Patterns Funding Sources with agency_id: #{agency&.id}")

    origin = { lat: @trip&.origin&.lat, lng: @trip&.origin&.lng }
    destination = { lat: @trip&.destination&.lat, lng: @trip&.destination&.lng }
    # TODO: Set these params from @trip.trip_time
    trip_date = nil
    start_time = nil
    end_time = nil

    travel_pattern_query = TravelPattern.filter_by_origin(travel_pattern_query, origin)
    travel_pattern_query =  TravelPattern.filter_by_destination(travel_pattern_query, destination)
    travel_pattern_query =  TravelPattern.filter_by_purpose(travel_pattern_query, @purpose)
    travel_pattern_query =  TravelPattern.filter_by_funding_sources(travel_pattern_query, @purpose, @booking_profile)
    travel_pattern_query =  TravelPattern.filter_by_date(travel_pattern_query, trip_date)
    travel_patterns =  TravelPattern.filter_by_time(travel_pattern_query, start_time, end_time)

    travel_patterns.each do |travel_pattern|
      funding_source_names = travel_pattern.funding_sources.pluck(:name)
      travel_pattern_funding_sources.concat(funding_source_names).uniq
    end

    return travel_pattern_funding_sources
  end

  ### Build a Funding Hash for the Trip using 1-Click's Rules
  def build_1click_funding_hash

    travel_pattern_funding_sources = []
    if Config.dashboard_mode == 'travel_patterns'
      travel_pattern_funding_sources = get_travel_pattern_funding_sources
      if travel_pattern_funding_sources.blank?
        # If configured to use travel patterns, return if they have no funding.
        return {}
      end
    end

    # Find the options that include the best funding source
    potential_options = [] # A list of options. Each one will be ultimately be the same funding source with potentially multiple sponsors
    best_index = nil
    arrayify(get_funding_options).each do |option|
      # Check if the funding source exists in the trip's matching travel patterns. If not, skip it.
      if option["type"] != "valid" || option["purpose"] != @purpose ||
        (Config.dashboard_mode == 'travel_patterns' && travel_pattern_funding_sources.index(option["funding_source"]).nil?)
        next
      end
      if option["funding_source"].in? @preferred_funding_sources and (potential_options == [] or @preferred_funding_sources.index(option["funding_source"]) < best_index) 
        best_index = @preferred_funding_sources.index(option["funding_source"])
        potential_options = [option] 
      elsif option["funding_source"].in? @preferred_funding_sources and @preferred_funding_sources.index(option["funding_source"]) == best_index
        potential_options << option 
      end
    end

    best_option = nil
    best_index = nil
    # Now Narrow it down based on sponsor
    potential_options.each do |option|
      if best_index == nil and option["sponsor"].in? @preferred_sponsors
        best_index = @preferred_sponsors.index(option["sponsor"])
        best_option = option 
      elsif option["sponsor"].in? @preferred_sponsors and @preferred_sponsors.index(option["sponsor"]) < best_index
        best_index = @preferred_sponsors.index(option["sponsor"])
        best_option = option
      end
    end

    if potential_options.blank?
      {}
    else
      {funding_source: best_option["funding_source"], purpose: @purpose, sponsor: best_option["sponsor"]}
    end

  end

  def build_ecolane_funding_hash
    url_options =  "/api/order/#{system_id}/query_preferred_fares"
    url = @url + url_options
    order =  build_order funding=false
    resp = send_request(url, 'POST', order)
    fare_hash = Hash.from_xml(resp.body)
    fares = fare_hash['fares']['fare']
    highest_priority_fare = []
    #When there is only one option in the fares table, it is  not returned as an array.  Turn it into an array
    unless fares.kind_of? Array
      fares = [fares]
    end
    fares.each do |fare|
      if highest_priority_fare.empty? or highest_priority_fare[3].to_f < fare['priority'].to_f
        highest_priority_fare = [fare['client_copay'].to_f/100.0, fare['funding']['funding_source'], fare['funding']['sponsor'], fare['priority']]
      end
    end
    [highest_priority_fare[0], { funding_source: highest_priority_fare[1], purpose: @purpose, sponsor: highest_priority_fare[2]}]
  end

  def discounts_hash
    if @use_ecolane_rules #use Ecolane Rules
      build_ecolane_discount_array
    else
      build_1click_discount_array
    end
  end

  def build_1click_discount_array 
    discount_array = []
    @guest_funding_sources.each do |funding_source|
      funding_source_hash = {funding_source: funding_source[:code], purpose: @guest_purpose}
      fare = get_1click_fare funding_source_hash
      unless fare.nil?
        discount_array.append({fare: fare, comment: funding_source[:desc], funding_source: funding_source[:code], base_fare: false})
      end
    end
    discount_array
  end

  def build_ecolane_discount_array
    url_options =  "/api/order/#{system_id}/query_preferred_fares"
    url = @url + url_options
    order = Nokogiri::XML(build_order)
    order = order.to_s
    resp = send_request(url, token, 'POST', order)

    begin
      resp_code = resp.code
    rescue
      return nil
    end

    if resp_code != "200"
      return nil
    end

    temp_hash = {}
    fare_hash = Hash.from_xml(resp.body)
    fares = fare_hash['fares']['fare']
    fares.each do |fare|
      new_funding_source = fare["funding"]["funding_source"]
      new_fare = fare["client_copay"].to_f/100
      new_comment = fare["funding"]["description"]

      current = temp_hash[new_funding_source]

      #If this is the first time seeing this funding source, save it.
      if current.nil?
        if not new_comment.nil? and not new_fare.nil?
          temp_hash[new_funding_source] = {fare: new_fare, comment: new_comment, funding_source: new_funding_source, base: false}
        end
      #If we've seen this funding source before, but the new fare is higher, save it.
      elsif current[:fare] < new_fare
        if not new_comment.nil? and not new_fare.nil?
          temp_hash[new_funding_source] = {fare: new_fare, comment: new_comment, funding_source: new_funding_source, base: false}
        end
      end
    end

    discounts = []
    temp_hash.each do |k,v|
      v[:funding_source] = k
      discounts << v
    end

    discounts

  end

  def iso8601ify dob 
    dob = dob.split('/')
    unless dob.count == 3
      return nil
    end
    begin
      dob = Date.parse(dob[1] + '/' + dob[0] + '/' + dob[2]).strftime("%Y/%m/%d")
    rescue  ArgumentError
      return nil
    end
    Date.iso8601(dob.delete('/'))
  end

  def arrayify thing 
    if thing.is_a? Array
      thing
    else
      if thing.nil? 
        return []
      else
        return [thing]
      end
    end
  end

  def yes_or_no value
    value.to_bool ? true : false
  end

  # If we synced trips from Ecolane, we need to identify which trips are actually round trips.
  # They are delivered to us as individual trips, and we will link them together.
  # Linking these lets users cancel them as a group, it also lets us pre-fill the most recent addresses in the user interface
  def link_trips 

    # First do the past trips, and then do the future trips
    [:future, :past].each do |times|
      if times == :future # Get all future trips
        trips = @user.trips.selected.future
      else # Get the most recent past 14 days of trips
        trips = @user.trips.selected.past.past_14_days.reverse
      end
      
      # Group trips on same day.
      trips_by_date = trips.group_by {|trip| trip.trip_time.in_time_zone.to_date}
      trips_by_date.each do |trip_date, same_day_trips|
        # Reset links on existing trips, unless trip has been created directly in 1click.
        same_day_trips.each do |trip|
          if trip.previous_trip and !trip&.selected_itinerary&.booking&.created_in_1click
            trip.previous_trip = nil
            trip.save 
          end
        end

        # Compare combinations of same day trips.
        same_day_trips.pluck(:id).combination(2).each do |trip_id, next_trip_id|
          trip = Trip.find_by(id: trip_id)
          next_trip = Trip.find_by(id: next_trip_id)

          # If this is already a round trip, and if trip has been created directly in 1click, 
          # don't try to re-link. Otherwise, continue.
          if (trip.previous_trip or trip.next_trip) and trip&.selected_itinerary&.booking&.created_in_1click
            next
          end

          # Are these trips on the same day?
          unless trip.trip_time.in_time_zone.to_date == next_trip.trip_time.in_time_zone.to_date
            next
          end

          #Does these trips have inverted origins/destinations?
          unless trip.origin.lat == next_trip.destination.lat and trip.origin.lng == next_trip.destination.lng
            next
          end
          unless trip.destination.lat == next_trip.origin.lat and trip.destination.lng == next_trip.origin.lng
            next
          end

          #Ok these trips passed all the tests, combine them into one trip
          next_trip.previous_trip = trip
          next_trip.save 

        end #trips.each
      end #trips_by_date.each
    end #times.each
  end #link_trips

end
