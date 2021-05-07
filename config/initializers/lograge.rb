require_relative '../../app/helpers/helper'

Rails.application.configure do
  # Lograge config
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.colorize_logging = false

  # TODO If the event includes a request.header["X-Auth-Email"] value, turn that to a thing
  config.lograge.custom_options = lambda do |event|
    {
      :params => event.payload[:params],
      :timestamp => Time.now,
      :data_access_type => LoggingHelper::check_if_phi(event.payload)
    }
  end
  puts "Lograge configured"
end