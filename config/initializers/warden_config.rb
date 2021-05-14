require_relative '../../lib/modules/logging_helper'

Warden::Manager.before_failure do |env, opts|
  puts opts
  puts opts[:message]
  puts opts[:message].class
  # log auth err here
  # add timestamp
  # add better comment for log
  json = {
    data_access_type: "PHI_AUTH_FAILURE",
    **opts,
    message: LoggingHelper::WARDEN_FAILURE_MESSAGES[opts[:message]],
    timestamp: Time.now
  }
  Rails.application.config.phi_logger.info(JSON::dump(json))
end