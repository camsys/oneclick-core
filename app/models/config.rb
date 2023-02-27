class Config < ApplicationRecord

  serialize :value

  validates :key, presence: true, uniqueness: true
  
  # List of rake tasks that can be scheduled
  AVAILABLE_SCHEDULED_TASKS = [
    :agency_setup_reminder_emails,
    :agency_update_reminder_emails,
    :service_update_reminder_emails,
    :user_profile_update_emails,
    :get_ride_pilot_purposes,
    :feedback_reminders,
    :purge_unused_guests,
    :sync_all_ecolane_users_3_days,
    :send_fixed_trip_reminders,
    :add_notification_preferences
  ].freeze

  # Default notification preferences for users, freezing for now
  DEFAULT_NOTIFICATION_PREFS = [7,3,1].freeze

  ##
  # The booking_api configuration sets which Booking APIs the TripPlanner is allowed to use when
  # creating Itineraries. Its default value is "all" which will allow any Booking API to be used.
  # It may also be set to "none" to disallow any Booking API or to the name of a specific API.
  # At this time lists of names are not supported.
  def self.booking_api(*args)
    booking_api = method_missing(:booking_api, *args)
    return "all" if booking_api.nil?
    return booking_api
  end

  # Returns the value of a setting when you say Config.<key>
  def self.method_missing(key, *args, &blk)
    # If the method ends in '=', set the config variable
    return set_config_variable(key.to_s.sub("=", ""), *args) if key.to_s.last == "="
    
    config = Config.find_by(key: key)
    return config.value unless config.nil?
    return Rails.application.config.send(key) if Rails.application.config.respond_to?(key)
    
    Rails.logger.warn("Warning: Config #{key} was not found in the database or the application configuration, defaulting to environment")
    return ENV[key.to_s] if ENV[key.to_s]
  end
  
  # Sets a config variable if possible
  def self.set_config_variable(key, *args)
    return false if Rails.application.config.respond_to?(key)
    return Config.find_or_create_by(key: key).update_attributes(value: args.first)
  end

end
