module BookingHelpers  
  
  ################
  # USER HELPERS #
  ################
  
  # Include in User model to allow booking
  module UserHelpers
    
    # Return's the user's booking profile associated with the passed service
    def booking_profile_for(service)
      booking_profiles.find_by(service_id: service.id)
    end
    
  end
  
  
  ###################
  # SERVICE HELPERS #
  ###################
  
  # Include in Service model to allow booking
  module ServiceHelpers
    
    # Configure including class
    def self.included(base)
      base.serialize :booking_details
    end
    
    # Returns the appropriate booking ambassador based on the booking_api field
    def booking_ambassador(opts={})
      case booking_api
      when "ridepilot"
        return RidePilotAmbassador.new(opts)
      else
        return nil
      end
    end
    
  end
  
  
  ################
  # TRIP HELPERS #
  ################
  
  # Include in Trip model to allow booking
  module TripHelpers

    # Configure including class
    def self.included(base)
      base.has_one :booking, through: :selected_itinerary
    end
    
    # Builds a booking for selected itinerary
    def build_booking(params={})
      selected_itinerary.try(:build_booking, params)
    end
    
    # Returns status of booked itinerary
    def booking_status
      booking.try(:status)
    end
    
    # Returns true/false if the trip is booked 
    # (based on existence of and status code in booking object)
    def booked?
      !!booking.try(:booked?)
    end
    
    # Returns true/false if the trip is canceled
    # (based on existence of and status code in booking object)
    def canceled?
      !!booking.try(:canceled?)
    end

  end
  
  
end
