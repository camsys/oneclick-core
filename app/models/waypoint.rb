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
    address_parts = [self.street_number, self.route, self.city, self.state, self.zip].compact.join(' ')
    full_name = self.name || ''  # Fallback to empty string if name is nil

    # Log details if full_name is empty or nil
    if full_name.nil? || full_name.empty?
      Rails.logger.debug "Waypoint ID: #{self.id} has no full name. Address Parts: #{address_parts.inspect}"
    end

    # Handle pipe filtering for the name
    short_name = full_name.split('|').first.strip

    # Log details if short_name is nil
    if short_name.nil?
      Rails.logger.debug "Waypoint ID: #{self.id} has nil short name. Full Name: #{full_name.inspect}"
    end

    # Check if short name is already present in the address components
    address_components = address_parts.split(',').map(&:strip)
    if address_components.include?(short_name)
      # Short name is already present, so use address_parts as is
      full_address = address_parts
    else
      # Short name is not present, so include it in the full address
      full_address = "#{short_name}, #{address_parts}"
    end

    # Remove any duplicate spaces to clean up the address
    full_address.gsub(/\s+/, ' ')
  end
  
end
