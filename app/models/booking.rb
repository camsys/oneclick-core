class Booking < ApplicationRecord
  
  ### ATTRIBUTES & ASSOCIATIONS ###
  belongs_to :itinerary
  has_one :service, through: :itinerary
  serialize :details
  
  ### CONSTANTS ###
  BOOKING_TYPES = {
    ride_pilot: "RidePilotBooking" #,
    # ecolane: EcolaneBooking,
    # trapeze: TrapezeBooking
  }.freeze
  
  BOOKING_TYPE_CODES = BOOKING_TYPES.keys.freeze
  BOOKING_TYPE_CLASSES = BOOKING_TYPES.values.freeze
  
  ### VALIDATIONS ###
  validates :type, presence: true, inclusion: BOOKING_TYPE_CLASSES
  
  
  ### INSTANCE METHODS ###
  
  # By default, returns true if the Booking object exists.
  # TODO: Method should be overwritten in subclass
  def booked?
    true
  end
  
  # Returns the booking's type code symbol
  def type_code
    BOOKING_TYPES.key(type)
  end
  
  
end
