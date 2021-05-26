require 'lograge/sql/extension'
require_relative '../../lib/modules/logging_helper'

Rails.application.configure do
  # Lograge config
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.colorize_logging = false

  config.lograge.custom_options = lambda do |event|
    head= !event.payload[:headers].nil? ? event.payload[:headers] : nil
    origin = !head.nil? ? head["HTTP_ORIGIN"] : nil
    ip = !head.nil? ? head["REMOTE_ADDR"] : nil
    puts "origin #{origin} ip #{ip}"
    status = LoggingHelper::check_if_devise_sign_in(event.payload)
    {
      :params => event.payload[:params],
      :timestamp => Time.now,
      :log_level => LoggingHelper::return_log_level(status),
      :origin => origin,
      :accessing_ip => ip
    }
  end
  config.lograge.ignore_custom = lambda { |event|
    LoggingHelper::check_if_phi(event.payload).nil?
  }
  puts "Lograge configured"
end