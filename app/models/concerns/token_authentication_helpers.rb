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
  
  # Resets user password to a randomly generated one. If successful, returns the
  # generated password
  def reset_user_password_to_random
    generated_password = Devise.friendly_token.first(8)
    if self.update_attributes(password: generated_password, password_confirmation: generated_password)
      return generated_password
    else
      return nil
    end
  end
  
end
