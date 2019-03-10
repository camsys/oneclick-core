class EcolaneAmbassador < BookingAmbassador

  attr_accessor :customer_number, :service, :confirmation, :system_id, :token, :trip, :customer_id
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
    add_missing_attributes
    #@funding_hash = booking.details[:funding_hash] unless booking.nil?
    @preferred_funding_sources = @service.booking_details.try(:[], :preferred_funding_sources).split(',').map{ |x| x.strip }
    @preferred_sponsors =  @service.booking_details.try(:[], :preferred_sponsors).split(',').map{ |x| x.strip } + [nil]
    @ada_funding_sources = @service.booking_details.try(:[], :ada_funding_sources).split(',').map{ |x| x.strip } + [nil]
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
  def sync
    fetch_customer_orders.try(:with_indifferent_access).try(:[], :orders).try(:[], :order).each do |order|
      occ_trip_from_ecolane_trip order
    end
  end

    # Books Trip (funding_source and sponsor must be specified)
  def book
    new_order
  end

  def cancel
    result = cancel_order
    # Unselect the itinerary on successful cancellation
    @itinerary.unselect if result
    # Update Booking object with status info and return it
    booking.update({status: status})
    return result
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
    return questions
  end

  ####################################################################
  ## Actual Calls to Ecolane 
  ####################################################################

  def new_order
    url_options = "/api/order/#{system_id}?overlaps=reject"
    url = @url + url_options
    order =  build_order
    resp = send_request(url, 'POST', order)
    if Hash.from_xml(resp.body).try(:with_indifferent_access).try(:[], :status).try(:[], :result) == "success"
      confirmation = Hash.from_xml(resp.body).try(:with_indifferent_access).try(:[], :status).try(:[], :success).try(:[], :resource_id) 
      eco_trip  = fetch_order(confirmation)["order"]
      booking = Booking.new(occ_booking_hash(eco_trip))
      booking.itinerary = itinerary
      booking.save
      return booking
    else
      return nil
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
    Hash.from_xml(resp.body)
  end

  # Get Single Order
  def fetch_order confirmation=@confirmation
    url_options = "/api/order/#{system_id}/#{confirmation}"
    resp = send_request(@url + url_options, token)
    Hash.from_xml(resp.body)
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

  # Cancel a Trip
  def cancel_order 
    unless @confirmation
      Rails.logger.debug "Unable to cancel itinerary #{itinerary.id} because to confirmation number is present in the booking."
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
      return true
    elsif status == 'canceled'
      Rails.logger.debug "Trip #{@confirmation}  already canceled."
      #The trip was not successfully deleted, because it was already canceled
      return true
    else
      Rails.logger.debug "Trip #{@confirmation}  cannot be canceled."
      #The trip is not canceled
      return false
    end

  end

  def get_preferred_fare
    sponsors = nil
    url_options =  "/api/order/#{system_id}/query_preferred_fares"
    url = @url + url_options

    #funding = {purpose: 'Medical'}
    #params[:funding] = funding

    order =  build_order
    resp = send_request(url, 'POST', order)
    return resp
    fare, funding_source, sponsor = unpack_fare_response_v9(resp)
    return true, {fare: fare, funding_source: funding_source, sponsor: sponsor}
  end

  # Find the fare for a trip.
  def get_fare
    #get_funding_hash
    url_options =  "/api/order/#{system_id}/queryfare"
    url = @url + url_options
    order =  build_order
    resp = Hash.from_xml(send_request(url, 'POST', order).body)
    resp.try(:with_indifferent_access).try(:[],:fare).try(:[],:client_copay).to_f/100 
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
    #TODO: Reduce calls and save this after the first time we ask for it.
    if false #use Ecolane Rules
      return {}
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
      Rails.logger.info Hash.from_xml(message).ai 
      resp = http.start {|http| http.request(req)}
      Rails.logger.info '------Response from Ecolane---------'
      Rails.logger.info "Code: #{resp.code}"
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


  # Get a list of trip purposes for a customer
  def get_trip_purposes 
    purposes = []
    customer_information = fetch_customer_information(funding=true)
    customer_information["customer"]["funding"]["funding_source"].each do |funding_source|
      unless funding_source["name"].in? @preferred_funding_sources
        next 
      end
      arrayify(funding_source["allowed"]).each do |allowed|
        purpose = allowed["purpose"]
        unless purpose.in? purposes #or purpose.downcase.strip.in? (disallowed_purposes.map { |p| p.downcase.strip } || "")
          purposes.append(purpose)
        end
      end
    end
    banned_purposes = @service.booking_details[:banned_purposes]
    purposes.sort.uniq - (banned_purposes.blank? ? [] : banned_purposes.split(',').map{ |x| x.strip })
  end

  # Lookup Customer Number from DOB (YYYY-MM-DD) and Last Name
  def lookup_customer_number params
    search_for_customers(params).try(:with_indifferent_access).try(:[], :search_results).try(:[], :customer).try(:[], :customer_number)
  end
  
  ### Create OCC Trip from Ecolane Trip ###
  def occ_trip_from_ecolane_trip eco_trip
    booking_id = eco_trip.try(:with_indifferent_access).try(:[], :id)
    itinerary = @user.itineraries.joins(:booking).find_by('bookings.confirmation = ? AND service_id = ?', booking_id, @service.id)

    # Calculate time window
    #raw_date = trap_trip.try(:with_indifferent_access).try(:[], :raw_date).in_time_zone.to_time
    #pick_up_leg = trap_trip.try(:with_indifferent_access).try(:[], :pick_up_leg)
    #seconds_since_midnight = pick_up_leg.try(:with_indifferent_access).try(:[], :display_early)

    #early_pu_time = raw_date + seconds_since_midnight.to_i.seconds
    #seconds_since_midnight = pick_up_l`eg.try(:with_indifferent_access).try(:[], :display_late)
    #late_pu_time = raw_date + seconds_since_midnight.to_i.seconds

    # This Trip has already been created, just update it with new times/status etc.
    if itinerary
      booking = itinerary.booking 
      #booking.latest_pu = late_pu_time
      #booking.earliest_pu = early_pu_time
      booking.update(occ_booking_hash(eco_trip))
      #TODO
      if booking.status == "canceled"
        itinerary.unselect
      end
      booking.save 
      return nil
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
      #booking.latest_pu = late_pu_time
      #booking.earliest_pu = early_pu_time
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
    trip_time = origin_negotiated.to_time
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
      lng:            eco_place.try(:with_indifferent_access).try(:[], :longitude)
    }
  end 

  def occ_itinerary_hash_from_eco_trip eco_trip
    origin = occ_place_from_eco_place(eco_trip.try(:with_indifferent_access).try(:[], :pickup).try(:[], :location))
    origin_negotiated = eco_trip.try(:with_indifferent_access).try(:[], :pickup).try(:[], :negotiated)
    destination = occ_place_from_eco_place(eco_trip.try(:with_indifferent_access).try(:[], :dropoff).try(:[], :location))
    destination_negotiated = eco_trip.try(:with_indifferent_access).try(:[], :dropoff).try(:[], :negotiated)
    destination_requested = eco_trip.try(:with_indifferent_access).try(:[], :dropoff).try(:[], :requested)
    fare = eco_trip.try(:with_indifferent_access).try(:[], :fare).try(:[], :client_copay)

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
    {
      confirmation: eco_trip.try(:with_indifferent_access).try(:[], :id), 
      type: "EcolaneBooking", 
      status: eco_trip.try(:with_indifferent_access).try(:[], :status),
      negotiated_pu: eco_trip.try(:with_indifferent_access).try(:[], :pickup).try(:[],:negotiated),
      negotiated_do: eco_trip.try(:with_indifferent_access).try(:[], :dropoff).try(:[],:negotiated)
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
      return false
    # If only one thing is returned, it comes as a hash.  Multilple items are returned as an array.
    # Since we want to see exactly 1 match, return true if this is a Hash and the account is enabled.
    elsif result["search_results"]["customer"].is_a? Hash
      customer = result["search_results"]["customer"]

      #First make sure that we are setup for self servce
      if (service.booking_details["require_selfservice_validation"].to_bool) and not (customer["status"] and customer["status"]["validated_for"] == "selfservice")
        return false, {note: "Ineligible for online booking"} 
      end

      if  customer["status"] and customer["status"]["state"] == "enabled"
        return true, customer
      else
        return false, customer
      end
    else
      return false, {}
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
        user = User.create!(
            email: "#{@customer_number}_#{@county}@ecolane_user.com", 
            password: random, 
            password_confirmation: random,            
          )
        profile.details = {customer_id: passenger["id"]}
        profile.booking_api = "ecolane"
        profile.user = user
      end

      # Update the user's name
      user = @booking_profile.user 
      user.first_name = passenger["first_name"]
      user.last_name = passenger["last_name"]     
      user.save  

      return user
    else
      return nil
    end
  end

  def build_order funding=true
    params = {todo: "TODO MAKE THIS WORK"}
    order_hash = {
        assistant: yes_or_no(params[:assistant]), 
        companions: 0,#params[:companions], 
        children: 0,#params[:children], 
        other_passengers: 0,#params[:other_passengers], 
        pickup: build_pu_hash,
        dropoff: build_do_hash}

    order_hash[:customer_id] = @customer_id

    if funding 
      order_hash[:funding] = get_funding_hash
    end

    order_xml = order_hash.to_xml(root: 'order', :dasherize => false)
    order_xml
  end

  #Build the hash for the pickup request
  def build_pu_hash
    if !trip.arrive_by
      pu_hash = {requested: trip.trip_time.xmlschema[0..-7], location: build_location_hash(trip.origin)}#, note: "TODO NOTE TO DRIVER"}
    else
      pu_hash = {location: build_location_hash(trip.origin)}#, note: "TODO NOTE TO DRIVER"}
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
    {street_number: place.street_number, street: place.route, city: place.city, 
      state: place.state || "PA", zip: place.zip, latitude: place.lat, longitude: place.lng}
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
    return mapping
  end

  ### Build a Funding Hash for the Trip using 1-Click's Rules 
  def build_1click_funding_hash

    # Find the options that include the best funding source
    potential_options = [] # A list of options. Each one will be ultimately be the same funding source with potentially multiple sponsors
    best_index = nil
    get_funding_options.each do |option|
      if option["type"] != "valid" || option["purpose"] != @purpose 
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
      return {}
    else
      return {funding_source: best_option["funding_source"], purpose: @purpose, sponsor: best_option["sponsor"]}
    end

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
      return thing 
    else
      return [thing]
    end
  end

  def yes_or_no value
    value.to_bool ? true : false
  end

end
