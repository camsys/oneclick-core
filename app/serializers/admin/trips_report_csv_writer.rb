module Admin
  class TripsReportCSVWriter < CSVWriter
    
    columns :trip_id, :trip_time, :traveler, :user_type, :traveler_county, :traveler_paratransit_id, :arrive_by, 
            :disposition_status,
            :purpose,
            :orig_addr, :orig_county, :orig_lat, :orig_lng,
            :dest_addr, :dest_county, :dest_lat, :dest_lng,
            :traveler_age, :traveler_ip, :traveler_accommodations, :traveler_eligibilities, :agency_name, :service_name, :booking_id, :booking_client_id, :is_round_trip, :booking_timestamp,
            :funding_source, :sponsor, :companions, :trip_note, :orig_addr, :dest_addr
    associations :origin, :destination, :user, :selected_itinerary

    FMR_COLUMNS = [
      :trip_time, :traveler, :arrive_by, :disposition_status, 
      :purpose, :orig_addr, :orig_lat, :orig_lng, 
      :dest_addr, :dest_lat, :dest_lng, :agency_name, :service_name, :booking_id, :booking_client_id, :is_round_trip, :booking_timestamp,
      :funding_source, :sponsor, :companions, :trip_note, :orig_addr, :dest_addr
    ]

    def self.in_travel_patterns_mode?
      Config.dashboard_mode.to_sym == :travel_patterns
    end

    def headers
      if self.class.in_travel_patterns_mode?
        # Only include FMR_COLUMNS if in travel patterns mode
        self.class.headers.slice(*FMR_COLUMNS)
      else
        self.class.headers
      end
    end

    def trip_id
      @record.id
    end

    def traveler
      @record.user && @record.user&.email
    end

    def agency_name
      @record.user.booking_profile.service.agency.name rescue 'No Agency'
    end    

    def service_name
      @record.user.booking_profile.service.name rescue 'No Service'
    end

    def booking_id
      @record.booking.confirmation rescue 'No Booking ID'
    end
    
    def booking_client_id
      @record.user.booking_profile.external_user_id rescue 'No Client ID'
    end    

    def is_round_trip
      @record.previous_trip.present? || @record.next_trip.present? ? 'Yes' : 'No'
    end    

    def booking_timestamp
      @record.booking.created_at.strftime("%Y-%m-%d %H:%M:%S") rescue 'No Booking Timestamp'
    end    

    def funding_source
      @record.booking.details.dig(:funding_hash, :funding_source) rescue 'No Funding Source'
    end
    
    def sponsor
      @record.booking.details.dig(:funding_hash, :sponsor) rescue 'No Sponsor'
    end
    
    def companions
      @record.booking.itinerary.companions rescue '0'
    end    

    def trip_note
      @record.booking.itinerary.note rescue 'nil'
    end 

    def formatted_address(waypoint)
      # Return 'No Address' if waypoint is nil
      return 'No Address' unless waypoint
      
      # Extract components and the name
      address_parts = [waypoint.street_number, waypoint.route, waypoint.city, waypoint.state, waypoint.zip].compact.join(' ')
      full_name = waypoint.name || '' # Fallback to empty string if name is nil
      
      # Handle pipe filtering for the name
      short_name = full_name.split('|').first.strip
      
      # Format full address with name and address components
      "#{short_name}, #{address_parts}"
    end
    
    def orig_addr
      @record.origin&.formatted_address
    end
    
    def dest_addr
      @record.destination&.formatted_address
    end
        
    def user_type
      if @record.user&.admin_or_staff? == true
        'Staff User'
        # NOTE: the below translations are 211 Ride specific and have values that are not the same
        # as the fallback value, nor are they values that you'd generally expect
      elsif @record.user&.guest? == true
        I18n.t('admin.reporting.guest') ||'Guest'
      elsif @record.user&.registered_traveler?
        I18n.t('admin.reporting.public_user') || 'Public User'
      else
        ''
      end
    end

    def traveler_county
      @record.user && @record.user.county
    end
    
    def traveler_paratransit_id
      @record.user && @record.user.paratransit_id
    end

    def trip_time
      @record.trip_time&.in_time_zone
    end

    def traveler
      @record.user&.email
    end

    def purpose
      puts
      if @record.external_purpose
        @record.external_purpose
      elsif @record.purpose
        @record.purpose.code
      else
        "N/A"
      end
    end
    
    def orig_addr
      @record.origin&.address
    end

    def orig_county
      @record.origin&.county
    end
    
    def orig_lat
      @record.origin&.lat
    end
    
    def orig_lng
      @record.origin&.lng
    end
    
    def dest_addr
      @record.destination&.address
    end

    def dest_county
      @record.destination&.county
    end

    def dest_lat
      @record.destination&.lat
    end
    
    def dest_lng
      @record.destination&.lng
    end 

    def traveler_age
      @record.user_age
    end

    def traveler_ip
      @record.user_ip
    end

    def traveler_accommodations
      @record.trip_accommodations.reduce('') {|string, acc_hash| "#{string}#{acc_hash&.accommodation&.code}; "}
    end

    def traveler_eligibilities
      @record.trip_eligibilities.reduce('') {|string, elg_hash| "#{string}#{elg_hash&.eligibility&.code}; "}
    end

    def disposition_status
      @record.disposition_status || Trip::DISPOSITION_STATUSES[:unknown]
    end

  end
end
