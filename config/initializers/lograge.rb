require 'lograge/sql/extension'
require_relative '../../lib/modules/logging_helper'

Rails.application.configure do
  # Lograge config
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.colorize_logging = false

  config.lograge.custom_options = lambda do |event|
    begin
      head = !event.payload[:headers].nil? ? event.payload[:headers] : nil
      origin = !head.nil? ? head["HTTP_ORIGIN"] : nil
      user = User.find_by(email:!head.nil? ? head["HTTP_X_USER_EMAIL"] : nil)

      deidentified_params = LoggingHelper::deidentify_params_phi(event.payload[:params])
      data_access_type = LoggingHelper::check_if_phi(event.payload)
      status = LoggingHelper::check_if_devise_sign_in(event.payload)
      {
        :params => deidentified_params,
        :user_id => user&.id,
        :data_access_type => data_access_type,
        :timestamp => Time.now,
        :log_level => LoggingHelper::return_log_level(status),
        :origin => origin,
        :duration => event.duration.to_i
      }
    rescue
      puts "Lograge failed, Could not log event"
      return
    end
  end
  puts "Lograge configured"
end