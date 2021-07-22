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

  # Takes in event.payload from a 'process_action.action_controller' ActiveSupport::Notifications:Event
  def self.check_if_phi(payload)
    is_modification_action = payload[:method] == 'POST' || payload[:method] == 'PUT' ||
      payload[:method] == 'PATCH' || payload[:method] == 'DELETE'
    if payload[:controller].is_a?(String) == false
      nil
    end
    controller = payload[:controller].to_sym

    # If the current controller && action is included in ACTIONS_ACCESSING_PHI
    # ... then log it as PHI access or modification
    if !ACTIONS_ACCESSING_PHI[controller].nil? && (ACTIONS_ACCESSING_PHI[controller] == '*' || ACTIONS_ACCESSING_PHI[controller].include?(payload[:action]))
      if is_modification_action
        'PHI_MODIFICATION'
      else
        'PHI_ACCESS'
      end
    else
      nil
    end
  end

  # Takes in event.payload from a 'process_action.action_controller' ActiveSupport::Notifications:Event
  def self.get_user(payload)
    begin
      user = User.find_by(email: payload[:headers]['X-User-Email']) || nil
      return user.nil? ? nil : user.id
    rescue
      puts "Logging helper, Get User method failed"
      return
    end
  end

  # Takes in an Integer arg which is a HTTP status number
  def self.return_log_level(status)
    if !status.is_a?(Integer)
      'UNKNOWN'
    elsif status >= 200 && status < 300
      'SUCCESS'
    elsif status >= 300 && status < 400
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
  # Takes in event.payload from a 'process_action.action_controller' ActiveSupport::Notifications:Event
  def self.check_if_devise_sign_in(payload)
    if payload[:status]
      payload[:status]
    elsif payload[:status].nil? && payload[:controller] == "Devise::SessionsController" && payload[:method] == "POST"
      401
    else
      302
    end
  end

  # Takes in event.payload[:params] from a 'process_action.action_controller' ActiveSupport::Notifications:Event
  def self.deidentify_params_phi(payload_params)
    begin
      user = payload_params[:user]
      session = payload_params[:session]
      has_no_user = user.nil? || user.empty?
      has_no_session = session.nil? || session.empty?
      if has_no_user && has_no_session
        return payload_params
      elsif has_no_session == false
        hash = !session[:dob].nil? ? {session: { dob: "[FILTERED]" }} : nil
        payload_params.merge(hash)
      else
        user_id = !user[:email].nil? ? User.find_by(email: user[:email])&.id : User.find(user[:id])
        hash = !user_id.nil? ? {user_id: user_id,email: "[FILTERED]"} : {}
        payload_params.merge(hash)
      end
    rescue
      puts "Logging Helper Failure"
        # ON ERROR, THEN  DON'T DEIDENTIFY PAYLOAD PARAMS AND RETURN SILENTLY
      return
    end
    end
  end
