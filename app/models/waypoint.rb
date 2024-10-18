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
    # Join the address parts, ensuring no nils are included
    address_parts = [self.street_number, self.route, self.city, self.state, self.zip].compact.join(' ')
    full_name = self.name || ''  # Default to empty string if name is nil
  
    # Extract short_name from full_name (before any pipe if present)
    short_name = full_name.split('|').first&.strip || ''
  
    # Log the components for debugging
    Rails.logger.info "Address Parts: #{address_parts}"
    Rails.logger.info "Full Name: #{full_name}"
    Rails.logger.info "Short Name: #{short_name}"
  
    # Build the formatted address
    if short_name == full_name
      full_address = full_name
    else
      full_address = "#{short_name}, (#{address_parts})"
    end
  
    # Remove duplicate spaces and trailing commas
    full_address = full_address.gsub(/\s+/, ' ').gsub(/,\s*$/, '').strip
  
    # Log the final formatted address
    Rails.logger.info "Formatted Address: #{full_address}"
  
    full_address
  end
  
  
end
