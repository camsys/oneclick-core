module PasswordChangeable
  ##
  # This module adds a `before_save` callback to the Devise model
  # that calls the `check_password_change` method.
  extend ActiveSupport::Concern

  ##
  # Registers a `before_save` callback that calls the `check_password_change` method.
  included do
    before_save :check_password_change
  end

  ##
  # Checks if the user's password has been changed and if the user's access is locked.
  # If both conditions are met, it unlocks the user's access.
  def check_password_change
    return unless encrypted_password_changed? && access_locked?
    unlock_access!
  end
end
