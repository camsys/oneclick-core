class MapService

  attr_accessor :itinerary

  def initialize(itinerary)
    @itinerary = itinerary
  end

  # Builds a Static Map Map Image using the Google API. It is used to create maps for Emails
  def create_static_map
    legs = @itinerary.legs
    markers = create_markers
    polylines = create_polylines

    params = {
        'size' => '700x435',
        'maptype' => 'roadmap',
    }

    iconUrls = {
        'blueMiniIcon' => 'https://maps.gstatic.com/intl/en_us/mapfiles/markers2/measle_blue.png',
        'startIcon' => 'http://maps.google.com/mapfiles/dd-start.png',
        'stopIcon' => 'http://maps.google.com/mapfiles/dd-end.png'
    }

    markersByIcon = markers.group_by { |m| m["iconClass"] }

    url = "https://maps.googleapis.com/maps/api/staticmap?" + params.to_query
    markersByIcon.keys.each do |iconClass|
      marker = '&markers=icon:' + iconUrls[iconClass]
      markersByIcon[iconClass].each do |icon|
        marker += '|' + icon["lat"].to_s + "," + icon["lng"].to_s
      end
      url += URI::encode(marker)
    end

    polylines.each do |polyline|
      color = polyline['options']['color'].nil? ? "0000ff" : polyline['options']['color']
      url += URI::encode("&path=color:0x#{color}|weight:5|enc:" + polyline['geom']['points'])
    end
    return url
  end

  # Create an array of map markers.
  def create_markers

    trip = @itinerary.trip
    legs = @itinerary.legs

    markers = []

    if legs
      legs.each do |leg|

        place = {:name => leg['from']['name'], :lat => leg['from']['lat'], :lon => leg['from']['lon']}
        markers << get_addr_marker(place, 'start_leg', 'blueMiniIcon')

        place = {:name => leg['to']['name'], :lat => leg['to']['lat'], :lon => leg['to']['lon']}
        markers << get_addr_marker(place, 'end_leg', 'blueMiniIcon') 

      end
    end

    # Add start and stop after legs to place above other markers
    place = {:name => trip.origin.name, :lat => trip.origin.lat, :lon => trip.origin.lng}
    markers << get_addr_marker(place, 'start', 'startIcon')
    place = {:name => trip.destination.name, :lat => trip.destination.lat, :lon => trip.destination.lng}
    markers << get_addr_marker(place, 'stop', 'stopIcon') 
    return markers
  end

  def get_addr_marker(addr, id, icon)
    {
      "id" => id,
      "lat" => addr[:lat],
      "lng" => addr[:lon],
      "name" => addr[:name],
      "iconClass" => icon,
      "title" =>  addr[:name]
    }
  end

  #Returns an array of polylines, one for each leg
  def create_polylines

    polylines = []
    @itinerary.legs.each_with_index do |leg, index|
      polylines << {
        "id" => index,
        "geom" => leg['legGeometry'].nil? ? [] : leg['legGeometry'],
        "options" => get_leg_display_options(leg)
      }
    end

    return polylines
  end

  # Gets leaflet rendering hash for a leg based on the mode of the leg
  def get_leg_display_options leg

    if leg['mode'].nil?
      a = {"className" => 'map-tripleg map-tripleg-unknown'}
    elsif leg['routeColor'].present?
      a = {"className" => "map-tripleg", "color" => leg['routeColor']}
    else
      a = {"className" => 'map-tripleg map-tripleg-' + leg['mode']}
    end

    return a
  end

end