module Admin
  class TripsReportCSVWriter < CSVWriter
    
    columns :trip_time, :traveler, :arrive_by, :purpose,
            :orig_addr, :orig_lat, :orig_lng,
            :dest_addr, :dest_lat, :dest_lng

    def traveler(trip)
      trip.user && trip.user.email
    end

    def purpose(trip)
      trip.purpose && trip.purpose.code
    end
    
    def orig_addr(trip)
      trip.origin && trip.origin.address
    end
    
    def orig_lat(trip)
      trip.origin && trip.origin.lat
    end
    
    def orig_lng(trip)
      trip.origin && trip.origin.lng
    end
    
    def dest_addr(trip)
      trip.destination && trip.destination.address
    end

    def dest_lat(trip)
      trip.destination && trip.destination.lat
    end
    
    def dest_lng(trip)
      trip.destination && trip.destination.lng
    end

  end
end
