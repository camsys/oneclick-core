# require 'json'
# require 'net/http'

class OTPService
  attr_accessor :base_url

  def initialize(base_url)
    @base_url = base_url
  end

  ###
  # from and to should be [lat,lng] arrays;
  # trip_datetime should be a DateTime object;
  # arrive_by should be a boolean
  # Accepts a hash of additional options, none of which are required to make the plan call run
  def plan(from, to, trip_datetime, arrive_by=true, options={})

    # Set Default Options
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

    begin
      resp = Net::HTTP.get_response(URI.parse(url))
    rescue Exception=>e
      return {'id'=>500, 'msg'=>e.to_s}
    end

    return resp

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
    hash = {'mode_transit': 'TRANSIT,WALK',
    'mode_bicycle_transit': 'TRANSIT,BICYCLE',
    'mode_park_transit':'CAR_PARK,WALK,TRANSIT',
    'mode_car_transit':'CAR,WALK,TRANSIT',
    'mode_bike_park_transit':'BICYCLE_PARK,WALK,TRANSIT',
    'mode_rail':'TRAINISH,WALK',
    'mode_bus':'BUSISH,WALK',
    'mode_walk':'WALK',
    'mode_car':'CAR',
    'mode_bicycle':'MODE_BICYCLE'}
    hash[trip_type.to_sym]
  end

end
