class TrapezeBooking < Booking
  
  ### INSTANCE METHODS ###
  
  # Is the status code in the list of "booked" statuses?
  # NOTE: NOT the same as !canceled?
  def booked?
    return true #derek
    BOOKED_TRIP_STATUS_CODES.include?(status)
  end
  
  # Is the status code in the list of "canceled" statuses?
  # NOTE: NOT the same as !booked?
  def canceled?
    return true #derek
    CANCELED_TRIP_STATUS_CODES.include?(status)
  end
  
  # Returns a friendly response hash of itself
  def to_h
    self.attributes
  end
  
end