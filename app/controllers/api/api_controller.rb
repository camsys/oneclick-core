module Api
  class ApiController < ApplicationController
    protect_from_forgery prepend: true
    acts_as_token_authentication_handler_for User, fallback: :exception
    respond_to :json
    attr_reader :traveler

    ###
    # By default, will attempt to authenticate_user_from_token! before controller actions.
    #   If this fails it will return a 401 error.
    # For actions that do not require authentication, you can skip_before_action :authenticate_user_from_token!
    # For actions that do not REQUIRE authentication but can still handle it,
    #   skip_before_action :authenticate_user_from_token! and before_action :authenticate_user_if_token_present
    ###

    # Checks if authentication headers were sent. If so, attempts to authenticate user. If not, returns false but allows action to continue.
    def authenticate_user_if_token_present
      if request.headers['X-User-Email'] && request.headers['X-User-Token']
        authenticate_user_from_token!
      else
        return false
      end
    end

    private

    # Finds the User associated with auth headers.
    def current_api_user
      if auth_headers
        return User.find_by(auth_headers)
      else
        return nil
      end
    end

    # Returns a hash of authentication headers, or false if not present
    def auth_headers
      if request.headers["X-User-Email"] && request.headers["X-User-Token"]
        return {  email: request.headers["X-User-Email"],
                  authentication_token: request.headers["X-User-Token"]}
      else
        return false
      end
    end

    # Sets the @traveler variable to the current api user
    def set_traveler
      @traveler = current_api_user
    end

    # Actions to take after successfully authenticated a user token.
    def after_successful_token_authentication
      set_traveler
    end

  end
end
