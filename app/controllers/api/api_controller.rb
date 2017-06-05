module Api
  class ApiController < ApplicationController
    protect_from_forgery prepend: true
    acts_as_token_authentication_handler_for User, fallback: :none
    respond_to :json
    attr_reader :traveler
    include JsonResponseHelper::ApiErrorCatcher # Catches 500 errors and sends back JSON with headers.

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
      render_failed_auth_response unless authentication_successful?
    end

    # Allows requests with "OPTIONS" method--pulled from old oneclick.
    def handle_options_request
      head(:ok) if request.request_method == "OPTIONS"
    end

    # Sends back a 404 error for bad routes
    def no_route
      render status: 404, json: json_response(:error, message: "Route does not exist")
    end

    protected

    # Actions to take after successfully authenticated a user token.
    # This is run automatically on successful token authentication
    def after_successful_token_authentication
      @traveler = current_api_user # Sets the @traveler variable to the current api user
    end

    # Finds the User associated with auth headers.
    def current_api_user
      auth_headers ? User.find_by(auth_headers) : nil
    end

    # Ensure that a user object is created and loaded as @traveler
    def current_or_guest_user
      if @traveler.nil?
        @traveler = create_guest_user
      end
      @traveler
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
    def render_failed_auth_response
      render status: 401,
        json: json_response(:fail, data: {user: "Valid user email and token must be present."})
    end

    # Returns true if authentication has successfully completed
    def authentication_successful?
      !!@traveler
    end
    
    
    ### RESPONSE METHODS ###
    # Based on JSend Specification
    
    # Renders a successful response, passing along a given object as data
    def success_response(data={})
      status = data.delete(:status) || 200
      {
        status: status,
        json: {
          status: "success",
          data: data
        }
      }
    end
    
    # Renders a failure response (client error), passing along a given object as data
    def fail_response(data={})
      status = data.delete(:status) || 400
      {
        status: status,
        json: {
          status: "fail",
          data: data
        }
      }
    end
    
    # Renders an error response (server error), passing along a given message
    def error_response(message="Server Error", opts={})
      status = opts.delete(:status) || 500
      {
        status: status,
        json: {
          status: "error",
          message: message
        }
      }
    end
    

    def create_guest_user
      u = User.create(first_name: "Guest", last_name: "User", email: "guest_#{Time.now.to_i}#{rand(100)}@example.com")
      u.save!(:validate => false)
      session[:guest_user_id] = u.id
      u
    end

  end
end
