class Config < ApplicationRecord

  serialize :value

  validates :key, presence: true, uniqueness: true
  
  # List of rake tasks that can be scheduled
  AVAILABLE_SCHEDULED_TASKS = [
    :agency_setup_reminder_emails,
    :get_ride_pilot_purposes
  ].freeze

  # Returns the value of a setting when you say Config.<key>
  def self.method_missing(key, *args, &blk)
    # If the method ends in '=', set the config variable
    return set_config_variable(key.to_s.sub("=", ""), *args) if key.to_s.last == "="
    
    config = Config.find_by(key: key)
    return config.value unless config.nil?
    return Rails.application.config.send(key) if Rails.application.config.respond_to?(key)
    return nil
  end
  
  # Sets a config variable if possible
  def self.set_config_variable(key, *args)
    return false if Rails.application.config.respond_to?(key)
    return Config.find_or_create_by(key: key).update_attributes(value: args.first)
  end

end
