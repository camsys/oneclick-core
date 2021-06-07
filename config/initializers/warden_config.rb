require_relative '../../lib/modules/logging_helper'

Warden::Manager.before_failure do |env, opts|
  # Adds logging for authentication failure
  # the notable event is when a user's account gets locked
  user_role = nil
  email = env["action_dispatch.request.parameters"][:user][:email]
  origin = env["HTTP_ORIGIN"]
  user = User.find_by(email: email)
  user_id = !user.nil? ? user.id : nil
  if opts[:message] == :locked
    if user&.admin?
      user_role = :admin
    elsif user&.staff?
      user_role = :staff
    else
      user_role = :traveler
    end
  end

  json = {
    data_access_type: "PHI_AUTH_FAILURE",
    user_role: user_role,
    user_id: user_id,
    message: opts[:message],
    origin: origin,
    **opts,
    timestamp: Time.now
  }
  Rails.application.config.logger.info(JSON::dump(json))
end

Warden::Manager.after_authentication except: :fetch do |user, auth, opts|
  # Adds logging for authentication success
  user_role = nil
  user_id = user.id
  if user.admin?
    user_role = :admin
  elsif user.staff?
    user_role = :staff
  else
    user_role = :traveler
  end
  origin = auth.env["HTTP_ORIGIN"]
  json = {
    data_access_type: "PHI_AUTH_SUCCESS",
    user_role: user_role,
    user_id: user_id,
    origin: origin,
    message: opts[:event],
    **opts,
    timestamp: Time.now
  }
  Rails.application.config.logger.info(JSON::dump(json))
end

Warden::Manager.before_logout do |user,auth,opts|
  # Adds logging for authentication success
  user_role = nil
  if user.admin?
    user_role = :admin
  elsif user.staff?
    user_role = :staff
  else
    user_role = :traveler
  end
  origin = auth.env["HTTP_ORIGIN"]
  json = {
    data_access_type: "PHI_AUTH_SESSION_DESTROYED",
    user_role: user_role,
    user_id: user.id,
    origin: origin,
    message: opts[:event],
    **opts,
    timestamp: Time.now
  }
  Rails.application.config.logger.info(JSON::dump(json))
end