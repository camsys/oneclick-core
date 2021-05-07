module LoggingHelper
  ROUTES_ACCESSING_PHI ||= %w[
    Api::V1::SessionsController
    Api::V1::TripsController
    Api::V1::UsersController
    Api::V1::PlacesController
    Admin::ReportsController
  ]


  def self.check_if_phi(payload)
    is_modification_action = payload[:method] == 'POST' || payload[:method] == 'PUT' ||
      payload[:method] == 'PATCH' || payload[:method] == 'DELETE'
    is_route_included = ROUTES_ACCESSING_PHI.include?(payload[:controller])

    if is_route_included
      if is_modification_action
        'PHI_MODIFICATION'
      else
        'PHI_ACCESS'
      end
    else
      'NORMAL_ACCESS'
    end
  end

  # for other events, we can probably write a utility class to do so
  def self.return_log_level(status)
    if (status >= 200 && status < 400)
      'INFO'
    elsif (status >= 400 && status < 500)
      'ERROR'
    else
      'UNKNOWN'
    end
  end

end
