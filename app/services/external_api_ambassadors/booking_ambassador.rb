# Template class for external booking API ambassadors
# All booking ambassadors should implement the following public methods:
  # book() => Booking object
  # cancel() => Booking object
  # status() => Booking object
# This template class handles basic intialization, setting various instance
# variables for associated models (trip, service, itinerary, etc.) in a cascade
# Also, sets up an HTTPRequestBundler for making API calls.
class BookingAmbassador
  
  attr_reader :itinerary, :trip, :booking_profile, :service, :user, :opts
  attr_accessor :http_request_bundler, 
                :url, 
                :token,
                :booking_options

  # Initialize with an options hash this should contain a reference to some
  # record model: A user, service, trip, itineary, or booking profile. This
  # will in turn be used to set other instance variables.
  def initialize(opts={})
    self.itinerary = opts[:itinerary]
    self.trip = opts[:trip] || @trip
    self.booking_profile = opts[:booking_profile] || @booking_profile
    self.service = opts[:service] || @service
    self.user = opts[:user] || @user # Defaults to trip.user
    
    @url = opts[:url] #Used for RidePilot and Trapeze
    @token = opts[:token] #Used for Ride:ilot and Trapeze

    @http_request_bundler = opts[:http_request_bundler] || HTTPRequestBundler.new #Used for RidePilot

    @booking_options = opts[:booking_options] || {}
  end
  

  ### CUSTOM SETTERS FOR INSTANCE VARIABLES ###
  
  # Custom setter for itinerary also sets trip, service, and user
  def itinerary=(new_itin)
    @itinerary = new_itin
    return unless @itinerary
    self.trip = @itinerary.try(:trip) || @trip
    self.service = @itinerary.try(:service) || @service
  end
  
  # Custom setter for trip also sets user
  def trip=(new_trip)
    @trip = new_trip
    return unless @trip
    @itinerary = @trip.selected_itinerary || @itinerary
    @user = @trip.try(:user) || @user
  end
  
  # Custom setter for booking_profile also sets user and service
  def booking_profile=(new_booking_profile)
    @booking_profile = new_booking_profile
    return unless @booking_profile
    @user = @booking_profile.try(:user) || @user
    @service = @booking_profile.try(:service) || @service
  end
  
  # Custom setter for user also sets booking profile if not set already
  def user=(new_user)
    @user = new_user
    return unless @user && @service
    @booking_profile ||= @user.try(:booking_profile_for, @service)
  end
  
  # Custom setter for service also sets @booking_profile if @user is set
  def service=(new_service)
    @service = new_service
    return unless @user && @service
    @booking_profile ||= @user.try(:booking_profile_for, @service)
  end
  
  
  ### STANDARD BOOKING ACTIONS ###
  # These methods should be overwritten in inheriting sub-class
  # If successful, they should return a Booking object. If unsuccessful,
  # they should return false.
  
  def book
    return false
  end
  
  def cancel
    return false
  end
  
  def status
    return false
  end
  
  
  ### OTHER METHODS TO OVERWRITE ###
  
  # Overwrite this method with a symbol for the booking api name
  def booking_api
    nil
  end

  # Create 1-Click Trips for Each Trip in the Booking System
  def sync
    nil
  end

  def booking
    Booking.find_or_initialize_by(
      type: Booking::BOOKING_TYPES[booking_api],
      itinerary_id: @itinerary.try(:id)
    )
  end
  
  # Used by Ecolane to return a hash of potential funding sources and prices
  def discounts_hash
    nil 
  end
  
  private
  
  ### HELPER METHODS ###
  
  # Makes a symbolic label for HTTP requests, out of an arbitrary # of identifiers
  # Appends service's ID to the label
  def request_label(*identifiers)
    ([booking_api] + identifiers + [@service.try(:id)]).join("_").to_sym
  end
  
  # Returns the trip's Booking, if available. Otherwise, builds a booking object
  #def booking
  #  Booking.find_or_initialize_by(
  #    type: Booking::BOOKING_TYPES[booking_api],
  #    itinerary_id: @itinerary.try(:id)
  #  )
  #end
  
end
