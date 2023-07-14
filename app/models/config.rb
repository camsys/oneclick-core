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

  DEFAULT_CONFIGS = {
    application_title: "", # (String) The title of the application. Mostly used in emails.
    bike_reluctance: 5, # (Integer) ???
    booking_api: "all", # (String) Declares which booking apis services may use. Other values include "none" and the name of an api.
    daily_scheduled_tasks: [],
    dashboard_mode: "default", # (String) Set to "travel_patterns" to enable the travel pattern workflow.
    dashboard_reports: [], # (Array<???>) ???
    ecolane_url: "", # (String) The url to ecolane's booking api.
    feedback_overdue_days: 5, # (Integer) The number of days before feedback is considered overdue.
    guest_user_email_domain: "example.com", # (String) The domain used to create guest emails.
    lyft_client_token: "", # (String) The application's client token for booking Lyft rides.
    maximum_booking_notice: 30, # (Integer) The maximum number of days into the future a user is allowed to book.
    max_walk_distance: 1000, # default max walk distance
    max_walk_minutes: 45, # (Integer) The maximum number of minutes a traveler is expected to walk when planing a trip.
    open_trip_planner: "", # (String) OTP's base url.
    open_trip_planner_version: "v1", # (String) Which version of OTP to use. The other option is "v2".
    otp_itinerary_quantity: 3,
    otp_car_park_quantity: 3,
    otp_transit_quantity: 3,
    otp_paratransit_quantity: 3,
    password_required_letters: 0,
    password_required_uppercase: 0,
    password_required_lowercase: 0,
    password_required_numerical: 0,
    password_required_special: 0,    
    # otp_max_itineraries_shown: 3,
    require_user_confirmation: false, # (Boolean) Requires user to confirm their email address within a certain timeframe.
    ride_pilot_purposes: {}, # (Hash<String, String>) A Hash of key value pairs containing the names and codes of purposes for Ride Pilot.
    ride_pilot_token: "", # (String) The application's client token for booking with Ride Pilot.
    ride_pilot_url: "", # (String) The url for booking rides with Ride Pilot's api.
    tff_api_key: "", # ???
    trapeze_ada_funding_sources: [],
    trapeze_check_polygon_id: nil, # (Integer) ???
    trapeze_ignore_polygon_id: nil, # (Integer) ???
    trapeze_token: "",
    trapeze_url: "",
    trapeze_user: "", # (String) ???
    uber_token: "",
    ui_url: "", # (String) The url for the frontend.
    walk_reluctance: 10 # (Integer) ???
  }

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
    return ENV[key.to_s] if ENV[key.to_s].present?
    return DEFAULT_CONFIGS[key.to_sym]
  end
  
  # Sets a config variable if possible
  def self.set_config_variable(key, *args)
    return false if Rails.application.config.respond_to?(key)
    return Config.find_or_create_by(key: key).update_attributes(value: args.first)
  end

end
