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
    full_name = self.name || ''  # Fallback to empty string if name is nil
  
    # Handle pipe filtering for the name and strip spaces
    short_name = full_name.split('|').first&.strip || ''
  
    # Log intermediate values
    Rails.logger.info "Address Parts: #{address_parts}"
    Rails.logger.info "Full Name: #{full_name}"
    Rails.logger.info "Short Name: #{short_name}"
  
    # Avoid repeating the short name in the formatted address
    if short_name.present? && short_name != address_parts
      full_address = "#{short_name}, #{address_parts}"
    else
      full_address = address_parts
    end
  
    # Clean up any extra spaces and commas
    full_address = full_address.gsub(/\s+/, ' ').gsub(/\s?,\s?$/, '').strip
  
    # Log the final formatted address
    Rails.logger.info "Formatted Address: #{full_address}"
  
    full_address
  end  
  
end
