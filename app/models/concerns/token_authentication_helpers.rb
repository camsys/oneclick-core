module TokenAuthenticationHelpers
  
  def reset_authentication_token
    update_attributes(authentication_token: nil)
    ensure_authentication_token
    authentication_token.present?
  end
  
  # expose private last_attempt? method via this alias
  # returns true if this is the last chance to enter password before locking account
  def on_last_attempt?
    last_attempt?
  end
  
  # Returns number of minutes before account will be unlocked
  def time_until_unlock
    return 0 unless access_locked?
    return ((User.unlock_in - (Time.current - locked_at)) / 60).round
  end
  
  # Resets reset password token and send reset password instructions by email.
  # Email will link to front end password reset URL. Returns the token sent in the e-mail.
  # Similar to devise method send_reset_password_instructions: https://github.com/plataformatec/devise/blob/master/lib/devise/models/recoverable.rb
  def send_api_v1_reset_password_instructions
    token = set_reset_password_token
    UserMailer.api_v1_reset_password_instructions(self, token).deliver
    token
  end
  
  # Resets the user's password to a random and sends them an email with the new password
  def send_api_v2_reset_password_instructions
    UserMailer.api_v2_reset_password_instructions(self, reset_user_password_to_random).deliver
  end

  # Resets the user's password to a random and sends them an email with the new password
  def send_api_v2_email_confirmation_instructions
    send_confirmation_instructions
  end
  
  # Resets user password to a randomly generated one. If successful, returns the
  # generated password
  def reset_user_password_to_random
    tries = 0
    max_tries = 10
    while tries < max_tries
      generated_password = "A1#{Devise.friendly_token.first(8)}" #Adds an A1 to the front of every token because 1-click requires a letter and number
      if self.update_attributes(password: generated_password, password_confirmation: generated_password)
        return generated_password
      elsif tries > max_tries 
        generated_password = "Newpassword1234"
        self.update_attributes(password: generated_password, password_confirmation: generated_password)
        return generated_password
      end
      tries += 1
    end
  end
  
  # Checks whether or not an API user is valid for authentication.
  def valid_for_api_authentication?(password=nil)
    # the valid_for_authentication? method is defined in Devise's models/authenticatable.rb and overloaded in models/lockable.rb
    # passed block will only run if user is NOT locked out
    valid_for_authentication? do
      # check if password is correct and user has been confirmed
      valid_password?(password) &&
      (confirmed? || confirmation_period_valid? || !confirmation_required?)
    end
  end
  
end
