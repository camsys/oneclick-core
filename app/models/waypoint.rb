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
  
  def to_s
    address
  end

  ## This is used for FMR given they often have names with pipes in them as well as addresses listed as the name
  # This prevents the name from being duplicated in the address and makes it clean for display
  def formatted_address
    # Join the address parts with spaces, skipping any nil values
    address_parts = [self.street_number, self.route, self.city, self.state, self.zip].compact.join(' ')
  
    # Use the short name if it isn't already part of the address
    short_name = (self.name || '').split('|').first&.strip || ''
  
    # Only add the short name if it's not already in the address parts
    if short_name.present? && !address_parts.include?(short_name)
      full_address = "#{short_name}, #{address_parts}"
    else
      full_address = address_parts
    end
  
    # Remove any extra spaces and ensure the address is clean
    full_address.gsub(/\s+/, ' ').strip
  end  
  
end
