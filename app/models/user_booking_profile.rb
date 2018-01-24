class UserBookingProfile < ApplicationRecord

  ### INCLUDES ###
  include Encryptable
  
  ### ATTRIBUTES AND ASSOCIATIONS ###
  belongs_to :user
  belongs_to :service
  
  serialize :details
  encrypt_attribute :external_password, 'BOOKING_PASSWORD_ENCRYPTION_KEY' # Encryption key stored in ENV variable of this name

  
  ### INSTANCE METHODS ###
  
  # Returns the appropriate booking ambassador based on the booking_api field
  def booking_ambassador(opts={})
    opts = {booking_profile: self}.merge(opts)
    case booking_api
    when "ride_pilot"
      return RidePilotAmbassador.new(opts)
    when "trapeze"
      return TrapezeAmbassador.new(opts)
    else
      return nil
    end
  end
  
  # Returns true/false if the user can be authenticated with the external booking service
  def authenticate?
    booking_ambassador.try(:authenticate_user?)
  end

  # Returns the prebooking questions for the user.  
  def prebooking_questions
    booking_ambassador.try(:prebooking_questions)
  end
    
end
