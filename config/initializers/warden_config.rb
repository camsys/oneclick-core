require_relative '../../lib/modules/logging_helper'
# NOTE: This file is required as Devise authentication doesn't get processed by the standard logger
# ... so we need to add callbacks for:
# 1. authentication failure
# 2. authentication success
# 3. user logout
# ... in order to properly log them as PHI actions and not just a generic request
Warden::Manager.before_failure do |env, opts|
  begin
    # Adds logging for authentication failure
    # the notable event is when a user's account gets locked
    user_role = nil
    email = env["action_dispatch.request.parameters"]&.[](:user)&.[](:email)
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
  rescue
    puts "Warden Auth Failure Logging Failed"
    exit
  end
end

Warden::Manager.after_authentication except: :fetch do |user, auth, opts|
  begin
    # When an Oversight Agency user signs in and their current agency is nil, reset it to their staff agency
    # - it's kind of hacky/ there's a nicer UI way to do this but this is faster
    if user.staff_agency&.oversight? && user.current_agency.nil?
      user.current_agency = user.staff_agency
    end
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
  rescue => e
    puts e
    puts "Warden auth success logging failed"
  end
end

Warden::Manager.before_logout do |user,auth,opts|
  begin
    # Adds logging for authentication success
    user_role = nil
    # NOTE: before_logout is being called for certain actions
    # ...when it shouldn't so this is a quick check to see if there's a user associated
    if user.nil?
      nil
    end
    # NOTE: The null checking is a monkey patch
    # ...for some reason FMR users that access the front end homepage
    # ...after logging in get signed out on the backend
    if user&.admin?
      user_role = :admin
    elsif user&.staff?
      user_role = :staff
    else
      user_role = :traveler
    end
    origin = auth.env["HTTP_ORIGIN"]
    json = {
      data_access_type: "PHI_AUTH_SESSION_DESTROYED",
      user_role: user_role,
      user_id: user&.id,
      origin: origin,
      message: opts[:event],
      **opts,
      timestamp: Time.now
    }
    Rails.application.config.logger.info(JSON::dump(json))
  rescue
    puts "Warden log out logging failed"
  end
end
