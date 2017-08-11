module BookingHelpers  
  
  ################
  # USER HELPERS #
  ################
  
  # Include in User model to allow booking
  module UserHelpers
    
    # Configure including class
    def self.included(base)
      base.has_many :booking_profiles, class_name: "UserBookingProfile", dependent: :destroy
      base.has_many :bookings, through: :itineraries
    end
    
    # Returns the user's first booking_profile
    def booking_profile
      booking_profiles.first
    end
    
    # Return's the user's booking profile associated with the passed service
    def booking_profile_for(service)
      booking_profiles.find_by(service_id: service.try(:id))
    end
    
    # Returns true if the user has a booking_profile for the given service
    def has_booking_profile_for?(service)
      booking_profile_for(service).present?
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
      opts = {service: self}.merge(opts)
      case booking_api
      when "ride_pilot"
        return RidePilotAmbassador.new(opts)
      else
        return nil
      end
    end
    
    # Returns true/false if service is (theoretically) bookable
    def bookable?
      booking_api.present? && booking_details.present?
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
    
    # Initializes a BookingAmbassador object of the appropriate type
    # based on the trip's selected service, passing in itself
    # along with any other options given.
    def booking_ambassador(opts={})
      selected_service.try(:booking_ambassador, {trip: self}.merge(opts))
    end

    # Books the selected itinerary, the passed itinerary, or returns false if no 
    # itinerary is selected or passed. Booking options may be passed as a hash.
    # It is useful to book using this method for debugging, as errors will be stored on the trip
    def book(itinerary=nil, opts={})
      itinerary_to_book = itineraries.find_by(id: itinerary.try(:id)) || selected_itinerary
      if itinerary_to_book.present? 
        itinerary_to_book.select
        return booking_ambassador(opts).book
      else
        return false
      end
    end

  end
  
  
  #####################
  # ITINERARY HELPERS #
  #####################
  
  module ItineraryHelpers
    
    # Configure including class
    def self.included(base)
      base.has_one :booking
      base.scope :booked_or_cancelled, -> { joins(:booking) }
    end
    
    # Initializes a BookingAmbassador object of the appropriate type
    # based on the itinerary's associated service, passing in itself
    # along with any other options given.
    def booking_ambassador(opts={})
      service.try(:booking_ambassador, {itinerary: self}.merge(opts))
    end
    
    # Books this itinerary
    def book(opts={})
      booking_ambassador(opts).book
    end
    
    # Cancels this itinerary
    def cancel(opts={})
      booking_ambassador(opts).cancel
    end
    
    # Returns true/false if the itin is booked 
    # (based on existence of and status code in booking object)
    def booked?
      !!booking.try(:booked?)
    end
    
    # Returns true/false if the itin is canceled
    # (based on existence of and status code in booking object)
    def canceled?
      !!booking.try(:canceled?)
    end
    
    # Attempts to return the confirmation # from the associated booking
    def booking_confirmation
      booking.try(:confirmation)
    end
    
    # Attempts to return the status code from the associated booking
    def booking_status
      booking.try(:status)
    end
    
  end
  
end
