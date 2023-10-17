module Admin
  class TripsReportCSVWriter < CSVWriter

    DEFAULT_COLUMNS = [
      :trip_id, :trip_time, :traveler, :user_type, :traveler_county, :traveler_paratransit_id, 
      :arrive_by, :disposition_status, :selected_trip_type, :purpose,
      :orig_addr, :orig_county, :orig_lat, :orig_lng,
      :dest_addr, :dest_county, :dest_lat, :dest_lng,
      :traveler_age, :traveler_ip, :traveler_accommodations, :traveler_eligibilities
    ]

    TRAVEL_PATTERNS_EXCLUDE = [
      :trip_id, :user_type, :traveler_county, :traveler_paratransit_id, 
      :orig_county, :dest_county, :traveler_age, :traveler_ip, 
      :traveler_accommodations, :traveler_eligibilities
    ]

    associations :origin, :destination, :user, :selected_itinerary

    def self.columns
      if in_travel_patterns_mode?
        DEFAULT_COLUMNS - TRAVEL_PATTERNS_EXCLUDE
      else
        DEFAULT_COLUMNS
      end
    end

    def self.in_travel_patterns_mode?
      Config.dashboard_mode.to_sym == :travel_patterns
    end

    def trip_id
      @record.id
    end

    def traveler
      @record.user && @record.user&.email
    end

    def user_type
      if @record.user&.admin_or_staff? == true
        '211 Ride Staff User'
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
    
    def selected_trip_type
      @record.selected_itinerary&.trip_type || (@record.details && @record.details[:trip_type]) || "N/A"
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
