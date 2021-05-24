module LoggingHelper
  # NOTE: THIS SHOULD MATCH WHAT'S IN THE:
  # ...1 CLICK HIPAA COMPLIANCE/ PHI ACCESS AND MODIFICATION IN OCC
  # ... CONFLUENCE DOC
  # TODO: Add API V2 routes that access PHI!
  ACTIONS_ACCESSING_PHI ||= {
    'Devise::SessionsController': '*',
    'Api::V1::SessionsController': '*',
    'Api::V1::TripsController': %w[
      create
      past_trips
      future_trips
    ],
    'Api::V1::UsersController': %w[
      profile
      update
      password
      request_reset
      reset
      trip_purposes
      lookup
    ],
    'Api::V1::PlacesController': '*',
    'Admin::ReportsController': %w[
      download_table
      trips_table
      users_table
      requests_table
    ],
    'Admin::UsersController': '*'
  }

  WARDEN_FAILURE_MESSAGES ||= {
    :not_found_in_database => "User not found in database, check for logs at this timestamp for more information",
    :invalid => "User credentials not valid, check , check for logs at this timestamp for more information",
    :last_attempt => "User credentials not valid and last attempt before lock out, check for logs at this timestamp for more information",
    :locked => "User account locked, check for logs at this timestamp for more information"
  }


  def self.check_if_phi(payload)
    is_modification_action = payload[:method] == 'POST' || payload[:method] == 'PUT' ||
      payload[:method] == 'PATCH' || payload[:method] == 'DELETE'
    controller = payload[:controller].to_sym

    # If the current controller && action is included in ACTIONS_ACCESSING_PHI
    # ... then log it as PHI access or modification
    if !ACTIONS_ACCESSING_PHI[controller].nil? && (ACTIONS_ACCESSING_PHI[controller] == '*' || ACTIONS_ACCESSING_PHI[controller].include?(payload[:action]))
      if is_modification_action
        'PHI_MODIFICATION'
      else
        'PHI_ACCESS'
      end
    end
  end

  def self.get_user(payload)
    user = User.find_by(email: payload[:headers]['X-User-Email']) || nil
    return user.nil? ? nil : user.id
  end

  def self.return_log_level(status)
    if status >= 200 && status < 400
      'INFO'
    elsif status >= 400 && status < 500
      'ERROR'
    else
      'UNKNOWN'
    end
  end

  # Check if the action's route is the sign in route
  # Need this because the sign in failure log event doesn't include the status key for some reason
  # Seems to be a warden auth failure handling thing
  def self.check_if_devise_sign_in(payload)
    if payload[:status]
      payload[:status]
    elsif payload[:status].nil? && payload[:controller] == "Devise::SessionsController" && payload[:method] == "POST"
      401
    else
      302
    end
  end

end
