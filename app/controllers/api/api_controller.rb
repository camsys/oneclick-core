module Api
  class ApiController < ApplicationController
    protect_from_forgery prepend: true
    acts_as_token_authentication_handler_for User, fallback: :none
    respond_to :json
    attr_reader :traveler
    include ApiErrorCatcher # Catches 500 errors and sends back JSON with headers

    ### TOKEN AUTHENTICATION NOTES ###
    # By default: Will attempt to authenticate user and set @traveler if
    # X-User-Email and X-User-Token headers are passed, but will not throw
    # an error if authentication fails.
    #
    # Use before_action :require_authentication to require authentication,
    # and respond with a 401 if it fails.
    #
    # To perform an action only if authentication was successful, use the
    # authentication_successful? boolean method.
    ##################################

    # Renders a 401 failure response if authentication was not successful
    def require_authentication
      failed_auth_response unless authentication_successful?
    end

    # DEPRECATE THIS? #
    # Allows requests with "OPTIONS" method--pulled from old oneclick.
    def handle_options_request
      head(:ok) if request.request_method == "OPTIONS"
    end

    protected

    # Actions to take after successfully authenticated a user token.
    # This is run automatically on successful token authentication
    def after_successful_token_authentication
      @traveler = current_api_user  # Sets the @traveler variable to the current api user
    end

    # Finds the User associated with auth headers.
    def current_api_user
      auth_headers ? User.find_by(auth_headers) : nil
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

    # Renders a failed user auth response
    def failed_auth_response
      render status: 401, json: { message: "Valid user email and token must be present."}
    end

    # Returns true if authentication has successfully completed
    def authentication_successful?
      !!@traveler
    end

  end
end
