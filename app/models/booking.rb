class Booking < ApplicationRecord
  
  ### ATTRIBUTES & ASSOCIATIONS ###
  belongs_to :itinerary
  has_one :service, through: :itinerary
  serialize :details
  
  ### CONSTANTS ###
  BOOKING_TYPES = {
    ride_pilot: "RidePilotBooking",
    ecolane: "EcolaneBooking",
    trapeze: "TrapezeBooking"
  }.with_indifferent_access.freeze
  
  BOOKING_TYPE_CODES = BOOKING_TYPES.keys.freeze
  BOOKING_TYPE_CLASSES = BOOKING_TYPES.values.freeze
  
  ### VALIDATIONS ###
  validates :type, presence: true, inclusion: BOOKING_TYPE_CLASSES
  
  
  ### INSTANCE METHODS ###
  
  # By default, returns true if the Booking object exists.
  # TODO: Method should be overwritten in subclass
  def booked?
    raise "You are calling the abstact Booking class's booked? method directly instead of implementing it in a subclass."
    true
  end
  
  # By default, returns false.
  # TODO: Method should be overwritten in subclass
  def canceled?
    raise "You are calling the abstact Booking class's canceled? method directly instead of implementing it in a subclass."
    false
  end
  
  # Returns the booking's type code symbol
  def type_code
    BOOKING_TYPES.key(type)
  end

  # Returns a friendly response hash of itself
  def to_h
    self.attributes
  end

  # Filters out irrelevant booking types for FMR
  def self.available_booking_types
    if Config.dashboard_mode.to_sym == :travel_patterns
      { ecolane: "EcolaneBooking" }
    else
      BOOKING_TYPES
    end
  end
  
end