require 'lograge/sql/extension'

Rails.application.configure do
  # Lograge config
  config.lograge.enabled = ENV['RAILS_LOG_TO_STDOUT'].present? ? true : false
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.colorize_logging = false

  config.lograge.custom_options = lambda do |event|
    { :params => event.payload[:params] }
  end
end