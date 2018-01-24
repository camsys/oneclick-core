class TrapezeBooking < Booking

  ### CONSTANTS ### => 
  TRAPEZE_STATUSES = {
    "U"      =>  "Unscheduled", 
    "S"      =>  "Scheduled", 
    "A"      =>  "Arrived", 
    "P"      =>  "Complete", 
    "NS"     =>  "No-Show", 
    "NM"     =>  "No-Show", 
    "NT"     =>  "No-Show", 
    "CA"     =>  "Cancelled in Advance", 
    "CL"     =>  "Cancelled Late",
    "CD"     =>  "Cancelled at Door",
    "CS"     =>  "Cancelled Same-Day",
    "CC"     =>  "Cancelled Site Closure",
    "CE"     =>  "Cancelled User Error"
  }.freeze
  
  BOOKED_TRIP_STATUS_CODES = [
    "U", "S", "A", "P"
  ].freeze
  
  CANCELED_TRIP_STATUS_CODES = [
    "NS", "NM", "NT", "CA", "CL", "CD", "CS", "CC", "CE"
  ].freeze
  
  ### INSTANCE METHODS ###
  
  # Is the status code in the list of "booked" statuses?
  # NOTE: NOT the same as !canceled?
  def booked?
    BOOKED_TRIP_STATUS_CODES.include?(status)
  end
  
  # Is the status code in the list of "canceled" statuses?
  # NOTE: NOT the same as !booked?
  def canceled?
    CANCELED_TRIP_STATUS_CODES.include?(status)
  end
  
  # Returns a friendly response hash of itself
  def to_h
    self.attributes
  end
  
end