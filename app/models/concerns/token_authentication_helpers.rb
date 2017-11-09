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
  
end
