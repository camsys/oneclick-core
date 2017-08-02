class Booking < ApplicationRecord
  
  ### ATTRIBUTES & ASSOCIATIONS ###
  belongs_to :itinerary
  has_one :service, through: :itinerary
  serialize :details
  
  ### CONSTANTS ###
  BOOKING_TYPES = {
    ride_pilot: RidePilotBooking #,
    # ecolane: EcolaneBooking,
    # trapeze: TrapezeBooking
  }.freeze
  
  BOOKING_TYPE_CODES = BOOKING_TYPES.keys.freeze
  BOOKING_TYPE_CLASS_NAMES = BOOKING_TYPES.values.map {|v| v.to_s }.freeze
  
  ### VALIDATIONS ###
  validates :type, presence: true, inclusion: BOOKING_TYPE_CLASS_NAMES
  
  
  ### INSTANCE METHODS ###
  
  # By default, returns true if the Booking object exists.
  # Method should be overwritten in subclass
  def booked?
    return true
  end
  
  
end
