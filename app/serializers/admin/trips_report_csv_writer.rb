module Admin
  class TripsReportCSVWriter < CSVWriter
    
    columns :trip_time, :traveler, :user_type, :traveler_county, :traveler_paratransit_id, :arrive_by, :purpose,
            :orig_addr, :orig_county, :orig_lat, :orig_lng,
            :dest_addr, :dest_county, :dest_lat, :dest_lng,
            :selected_trip_type, :traveler_age, :traveler_ip, :traveler_accommodations, :traveler_eligibilities
    associations :origin, :destination, :user, :selected_itinerary

    def traveler
      @record.user && @record.user.email
    end

    def user_type
      puts @record.user['last_sign_in_ip']
      if @record.user&.admin_or_staff? == true
        '211 Ride Staff User'
      elsif @record.user&.guest? == true
        'Guest'
      else
        'Public User'
      end
    end

    def traveler_county
      @record.user && @record.user.county
    end

    def traveler_paratransit_id
      @record.user && @record.user.paratransit_id
    end

    def purpose
      @record.purpose && @record.purpose.code
    end
    
    def orig_addr
      @record.origin && @record.origin.address
    end

    def orig_county
      @record.origin&.county
    end

    def orig_lat
      @record.origin && @record.origin.lat
    end
    
    def orig_lng
      @record.origin && @record.origin.lng
    end
    
    def dest_addr
      @record.destination && @record.destination.address
    end

    def dest_county
      @record.destination&.county
    end

    def dest_lat
      @record.destination && @record.destination.lat
    end
    
    def dest_lng
      @record.destination && @record.destination.lng
    end

    # 211 Ride/ OCC-IEUW SPECIFIC: pull trip types from the generated itineraries that are attached to a trip
    def selected_trip_type
      @record.itineraries.pluck(:trip_type).uniq.reduce('') {|string, trip_type| "#{string}#{trip_type}; "}
    end

    def traveler_age
      @record.user_age
    end

    def traveler_ip
      @record.user_ip
    end

    def traveler_accommodations
      @record.user.accommodations.reduce('') {|string, acc_hash| "#{string}#{acc_hash.code}; "}
    end

    def traveler_eligibilities
      @record.user.eligibilities.reduce('') {|string, acc_hash| "#{string}#{acc_hash.code}; "}
    end

  end
end
