class Waypoint < Place
  has_one :trip_as_origin, foreign_key: "origin_id", class_name: "Trip"
  has_one :trip_as_destination, foreign_key: "destination_id", class_name: "Trip"

  def trip
    trip_as_origin || trip_as_destination
  end
  
  # Returns a full formatted address string
  def address
    [
      [street_number, route].compact.join(' '),
      city,
      [state, zip].compact.join(' ')
    ].compact.join(', ')
  end

  def formatted_address
    # Extract components and the name
    address_parts = [waypoint.street_number, waypoint.route, waypoint.city, waypoint.state, waypoint.zip].compact.join(' ')
    full_name = waypoint.name || '' # Fallback to empty string if name is nil
    
    # Handle pipe filtering for the name
    short_name = full_name.split('|').first.strip
    
    # Format full address with name and address components
    "#{short_name}, #{address_parts}"
  end
  
  def to_s
    address
  end
  
end
