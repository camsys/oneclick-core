require_relative '../../lib/modules/logging_helper'

Warden::Manager.before_failure do |env, opts|
  # Adds logging for authentication failure
  # the notable event is when a user's account gets locked
  json = {
    data_access_type: "PHI_AUTH_FAILURE",
    message_tag: opts[:message],
    **opts,
    message: LoggingHelper::WARDEN_FAILURE_MESSAGES[opts[:message]],
    timestamp: Time.now
  }
  Rails.application.config.phi_logger.info(JSON::dump(json))
end