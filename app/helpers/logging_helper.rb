module LoggingHelper
  ROUTES_ACCESSING_PHI = %w[
    Api::V1::SessionsController
    Api::V1::TripsController
    Api::V1::UsersController
    Api::V1::PlacesController
    Admin::ReportsController
  ]

  # manually log to a hipaa long on certain events. just reuse the APIREQUESTLOGGER service to do so
  # it's gotta output as JSON though otherwise there's no point
  def dump_json(payload)
    # TODO: also need to differentiate between plain PHI ACCESS and PHI MODIFICATION
    # Logging event type along with a timestamp
    JSON::dump(payload.merge({event_type: 'PHI_ACCESS', timestamp: Time.now, level: return_log_level(payload[:status])}))
  end

  # for other events, we can probably write a utility class to do so
  def return_log_level(status)
    if (status >= 200 && status < 400)
      'INFO'
    elsif (status >= 400 && status < 500)
      'ERROR'
    else
      'UNKNOWN'
    end
  end

end
