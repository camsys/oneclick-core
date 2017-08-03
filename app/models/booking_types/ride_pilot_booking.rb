class RidePilotBooking < Booking
  
  ### CONSTANTS ###
  RIDE_PILOT_STATUSES = {
    "COMP"      =>  "Complete", 
    "CANC"      =>  "Cancelled", 
    "UNMET"     =>  "Unmet Need", 
    "STNBY"     =>  "Standby", 
    "NS"        =>  "No-show", 
    "MT"        =>  "Missed Trip", 
    "LTCANC"    =>  "Late Cancel", 
    "SDCANC"    =>  "Same Day Cancel", 
    "TD"        =>  "Turned Down",
    "scheduled" =>  "Scheduled",
    "scheduled_to_cab" => "Scheduled to Cab",
    "requested" => "Requested"
  }.freeze
  
  BOOKED_TRIP_STATUS_CODES = [
    "COMP", "STNBY", "scheduled", "scheduled_to_cab", "requested"
  ].freeze
  
  CANCELED_TRIP_STATUS_CODES = [
    "CANC", "NS", "MT", "LTCANC", "SDCANC", "TD"
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
