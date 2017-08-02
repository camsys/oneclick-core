module Booking
  
  
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
  
end
