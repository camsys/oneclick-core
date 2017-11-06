# require 'json'
# require 'net/http'
# require 'eventmachine' # For multi_plan
# require 'em-http' # For multi_plan

module OTPServices

  class OTPService
    attr_accessor :base_url

    def initialize(base_url="")
      @base_url = base_url
    end

    # Makes multiple OTP requests in parallel, and returns once they're all done.
    # Send it a list or array of request hashes.
    def multi_plan(*requests)
      requests = requests.flatten
      responses = nil
      EM.run do
        multi = EM::MultiRequest.new
        requests.each_with_index do |request, i|
          url = plan_url(request)
          multi.add (request[:label] || "req#{i}".to_sym), EM::HttpRequest.new(url, connect_timeout: 3, inactivity_timeout: 3).get
        end

        responses = nil
        multi.callback do
          EM.stop
          responses = multi.responses
        end
      end

      return responses

    end

    # Constructs an OTP request url
    def plan_url(request)
      build_url(request[:from], request[:to], request[:trip_time], request[:arrive_by], request[:options] || {})
    end

    ###
    # from and to should be [lat,lng] arrays;
    # trip_datetime should be a DateTime object;
    # arrive_by should be a boolean
    # Accepts a hash of additional options, none of which are required to make the plan call run
    def plan(from, to, trip_datetime, arrive_by=true, options={})

      url = build_url(from, to, trip_datetime, arrive_by, options)

      begin
        resp = Net::HTTP.get_response(URI.parse(url))
      rescue Exception=>e
        return {'id'=>500, 'msg'=>e.to_s}
      end

      return resp

    end

    def build_url(from, to, trip_datetime, arrive_by, options={})
      # Set Default Options
      arrive_by = arrive_by.nil? ? true : arrive_by
      mode = options[:mode] || "TRANSIT,WALK"
      wheelchair = options[:wheelchair] || "false"
      walk_speed = options[:walk_speed] || 3.0 #walk_speed is defined in MPH and converted to m/s before going to OTP
      max_walk_distance = options[:max_walk_distance] || 2 #max_walk_distance is defined in miles and converted to meters before going to OTP
      max_bicycle_distance = options[:max_bicycle_distance] || 5
      optimize = options[:optimize] || 'QUICK'
      num_itineraries = options[:num_itineraries] || 3
      min_transfer_time = options[:min_transfer_time] || nil
      max_transfer_time = options[:max_transfer_time] || nil
      banned_routes = options[:banned_routes] || nil
      preferred_routes = options[:preferred_routes] || nil

      #Parameters
      time = trip_datetime.strftime("%-I:%M%p")
      date = trip_datetime.strftime("%Y-%m-%d")

      plan_url = @base_url + '/plan?'

      url_options = "&time=" + time
      url_options += "&mode=" + mode + "&date=" + date
      url_options += "&toPlace=" + to[0].to_s + ',' + to[1].to_s + "&fromPlace=" + from[0].to_s + ',' + from[1].to_s
      url_options += "&wheelchair=" + wheelchair.to_s
      url_options += "&arriveBy=" + arrive_by.to_s
      url_options += "&walkSpeed=" + (0.44704*walk_speed).to_s
      url_options += "&showIntermediateStops=" + "true"
      url_options += "&showStopTimes=" + "true"
      url_options += "&showNextFromDeparture=true"

      if banned_routes
        url_options += "&bannedRoutes=" + banned_routes
      end

      if preferred_routes
        url_options += "&preferredRoutes=" + preferred_routes
        url_options += "&otherThanPreferredRoutesPenalty=7200"#VERY High penalty for not using the preferred route
      end

      unless min_transfer_time.nil?
        url_options += "&minTransferTime=" + min_transfer_time.to_s
      end

      unless max_transfer_time.nil?
        url_options += "&maxTransferTime=" + max_transfer_time.to_s
      end

      #If it's a bicycle trip, OTP uses walk distance as the bicycle distance
      if mode == "TRANSIT,BICYCLE" or mode == "BICYCLE"
        url_options += "&maxWalkDistance=" + (1609.34*(max_bicycle_distance || 5.0)).to_s
      else
        url_options += "&maxWalkDistance=" + (1609.34*max_walk_distance).to_s
      end

      url_options += "&numItineraries=" + num_itineraries.to_s

      # Unless the optimiziton = QUICK (which is the default), set additional parameters
      case optimize.downcase
      when 'walking'
        url_options += "&walkReluctance=" + "20"
      when 'transfers'
        url_options += "&transferPenalty=" + "1800"
      end

      url = plan_url + url_options

      Rails.logger.info url

      return url
    end

    def last_built
      url = @base_url
      resp = Net::HTTP.get_response(URI.parse(url))
      data = JSON.parse(resp.body)
      time = data['buildTime']/1000
      return Time.at(time)
    end

    def get_stops
      stops_path = '/index/stops'
      url = @base_url + stops_path
      resp = Net::HTTP.get_response(URI.parse(url))
      return JSON.parse(resp.body)
    end

    def get_routes
      routes_path = '/index/routes'
      url = @base_url + routes_path
      resp = Net::HTTP.get_response(URI.parse(url))
      return JSON.parse(resp.body)
    end

    def get_first_feed_id
      path = '/index/feeds'
      url = @base_url + path
      resp = Net::HTTP.get_response(URI.parse(url))
      return JSON.parse(resp.body).first
    end

    def get_stoptimes trip_id, agency_id=1
      path = '/index/trips/' + agency_id.to_s + ':' + trip_id.to_s + '/stoptimes'
      url = @base_url + path
      resp = Net::HTTP.get_response(URI.parse(url))
      return JSON.parse(resp.body)
    end

    def get_otp_mode trip_type
      hash = {'transit': 'TRANSIT,WALK',
      'bicycle_transit': 'TRANSIT,BICYCLE',
      'park_transit':'CAR_PARK,WALK,TRANSIT',
      'car_transit':'CAR,WALK,TRANSIT',
      'bike_park_transit':'BICYCLE_PARK,WALK,TRANSIT',
      'rail':'TRAINISH,WALK',
      'bus':'BUSISH,WALK',
      'walk':'WALK',
      'car':'CAR',
      'bicycle':'BICYCLE'}
      hash[trip_type.to_sym]
    end

    # Wraps a response body in an OTPResponse object for easy inspection and manipulation
    def unpack(response)
      return OTPResponse.new(response)
    end

  end

  # Wrapper class for OTP Responses
  class OTPResponse
    attr_accessor :response, :itineraries

    # Pass a response body hash (e.g. parsed JSON) to initialize
    def initialize(response)
      response = JSON.parse(response) if response.is_a?(String)
      @response = response.with_indifferent_access
      @itineraries = extract_itineraries
    end

    # Allows you to access the response with [key] method
    # first converts key to lowerCamelCase
    def [](key)
      @response[key.to_s.camelcase(:lower)]
    end

    # Returns the array of itineraries
    def extract_itineraries
      return [] unless @response && @response[:plan] && @response[:plan][:itineraries]
      @response[:plan][:itineraries].map {|i| OTPItinerary.new(i)}
    end

  end


  # Wrapper class for OTP Itineraries
  class OTPItinerary
    attr_accessor :itinerary

    # Pass an OTP itinerary hash (e.g. parsed JSON) to initialize
    def initialize(itinerary)
      itinerary = JSON.parse(itinerary) if itinerary.is_a?(String)
      @itinerary = itinerary.with_indifferent_access
    end

    # Allows you to access the itinerary with [key] method
    # first converts key to lowerCamelCase
    def [](key)
      @itinerary[key.to_s.camelcase(:lower)]
    end

    # Extracts the fare value in dollars
    def fare_in_dollars
      @itinerary['fare'] &&
      @itinerary['fare']['fare'] &&
      @itinerary['fare']['fare']['regular'] &&
      @itinerary['fare']['fare']['regular']['cents'].to_f/100.0
    end

    # Getter method for itinerary's legs
    def legs
      OTPLegs.new(@itinerary['legs'] || [])
    end

    # Setter method for itinerary's legs
    def legs=(new_legs)
      @itinerary['legs'] = new_legs.try(:to_a)
    end
    
  end


  # Wrapper class for OTP Legs array, providing helper methods
  class OTPLegs
    attr_accessor :legs
    
    # Pass an OTP legs array (e.g. parsed or un-parsed JSON) to initialize
    def initialize(legs)
      
      # Parse the legs array if it's a JSON string
      legs = JSON.parse(legs) if legs.is_a?(String)
      
      # Make the legs array an array of hashes with indifferent access
      @legs = legs.map {|l| l.try(:with_indifferent_access) }.compact
    end
    
    def to_a
      @legs
    end
    
    def to_s
      @legs.to_s
    end
    
    # Returns first instance of an attribute from the legs, or the first leg if
    # no attribute is passed
    def first(attribute=nil)
      return @legs.pluck(attribute).first if attribute
      @legs.first || {}
    end
    
    # Returns an array of all non-nil instances of the given value in the legs
    def pluck(attribute)
      @legs.pluck(attribute).compact
    end
    
    # Sums up an attribute across all legs, ignoring nil and non-numeric values
    def sum_by(attribute)
      @legs.pluck(attribute).select{|i| i.is_a?(Numeric)}.reduce(&:+)
    end
  
  end

end
