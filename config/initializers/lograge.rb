require 'lograge/sql/extension'
require_relative '../../lib/modules/logging_helper'

Rails.application.configure do
  # Lograge config
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.colorize_logging = false

  config.lograge.custom_options = lambda do |event|
    status = LoggingHelper::check_if_devise_sign_in(event.payload)
    {
      :params => event.payload[:params],
      :timestamp => Time.now,
      :log_level => LoggingHelper::return_log_level(status)
    }
  end
  puts "Lograge configured"
end