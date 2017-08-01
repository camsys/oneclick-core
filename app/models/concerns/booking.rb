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
    
    
    
    
  end
  
end
