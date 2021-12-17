module Admin
  class TripsReportCSVWriter < CSVWriter
    
    columns :trip_time, :traveler, :arrive_by,
            :disposition_status,
            :selected_trip_type,
            :purpose,
            :orig_addr, :orig_lat, :orig_lng,
            :dest_addr, :dest_lat, :dest_lng
    associations :origin, :destination, :user, :selected_itinerary

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
    
    def orig_lat
      @record.origin&.lat
    end
    
    def orig_lng
      @record.origin&.lng
    end
    
    def dest_addr
      @record.destination&.address
    end

    def dest_lat
      @record.destination&.lat
    end
    
    def dest_lng
      @record.destination&.lng
    end
    
    def selected_trip_type
      @record.selected_itinerary&.trip_type || "N/A"
    end

    def disposition_status
      @record.disposition_status || Trip::DISPOSITION_STATUSES[:unknown]
    end

  end
end
