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

  # Booked is only implimented in EcolaneBooking for now.
  scope :booked, -> {
    err = NoMethodError.new("You are calling the abstact Booking class's booked scope directly instead of implementing it in a subclass.")
    raise err unless self == Booking

    BOOKING_TYPE_CLASSES.map(&:constantize).reduce (none) { |query, booking_class|
      begin
        query.or(booking_class.booked)
      rescue err.class => e
        query
      end
    }
  }

  scope :not_booked, -> {
    err = NoMethodError.new("You are calling the abstact Booking class's not_booked scope directly instead of implementing it in a subclass.")
    raise err unless self == Booking

    BOOKING_TYPE_CLASSES.map(&:constantize).reduce (none) { |query, booking_class|
      begin
        query.or(booking_class.not_booked)
      rescue err.class => e
        query
      end
    }
  }
  ### INSTANCE METHODS ###
  
  # By default, returns true if the Booking object exists
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
  
end
