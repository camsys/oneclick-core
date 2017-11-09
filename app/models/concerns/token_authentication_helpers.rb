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
    return ((Time.current - locked_at) / 60).round
  end
  
end
