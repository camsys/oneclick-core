module Api
  
  ### NOTES ###
  # Base controller for API Controllers
  # Automatically attempts to authenticate users, but does not enforce
    #  unless explicitly called to do so.
  # Includes helper methods to serve JSON responses that the JSend specification
    # API V2 responses should all conform to this specification
  #############  
    
  class ApiController < ApplicationController
    protect_from_forgery prepend: true
    acts_as_token_authentication_handler_for User, fallback: :none
    respond_to :json
    attr_reader :traveler, :errors
    include JsonResponseHelper::ApiErrorCatcher # Catches 500 errors and sends back JSON with headers.

    before_action :initialize_errors_hash, :set_locale

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
    
    # Set the locale based on passed param, user's preferred locale, or default
    def set_locale
      @locale = Locale.find_by(name: params[:locale]).try(:name) || 
                @traveler.try(:preferred_locale).try(:name) || 
                I18n.default_locale.to_s
    end
    
    # Sets the @traveler variable to the current api user
    def set_traveler
      @traveler = current_api_user
    end
    
    protected

    # Actions to take after successfully authenticated a user token.
    # This is run automatically on successful token authentication
    def after_successful_token_authentication
      set_traveler
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
    # If the serializer option is passed, will attempt to serialize the data
    # with the passed serializer
    def success_response(data={}, opts={})
      status = opts.delete(:status) || 200 # Status code is 200 by default
      serializer_opts = opts.delete(:serializer_opts) || { include: ['*.*'] } # By default, serialize 2 levels of nesting
      @root = opts.delete(:root) || nil # By default, no root key
      @serializer = opts.delete(:serializer) || nil # If specifying serializer
      
      # Check if an ActiveRecord object or collection was passed, and if so, serialize it
      if data.is_a?(ActiveRecord::Relation)
        data = package_collection(data, serializer_opts)
      elsif data.is_a?(ActiveRecord::Base)
        data = package_record(data, serializer_opts)
      end
      
      # Package data within a root key if necessary  
      data = { @root => data } if @root
      
      # Return a JSend-compliant hash
      {
        status: status,
        json: {
          status: "success",
          data: data
        }
      }
    end
    
    # Serialize the collection of records with the default serializer and any options.
    # Also, set the root key to the appropriate plural, if it hasn't been set manually.
    def package_collection(collection, opts={})
      @root ||= collection.klass.name.underscore.pluralize
      collection.map {|record| package_record(record, opts) }
    end
    
    # Serialize the record with the default serializer and any options.
    # Also, set the root key to the appropriate singular, if it hasn't been set already.
    def package_record(record, opts={})
      @root ||= record.class.name.underscore
      serializer_instance = @serializer ? @serializer.new(record, opts) : get_serializer(record, opts)
      serializer_instance.serializable_hash
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
      u = GuestUserHelper.new.build_guest
      u.save!(:validate => false)
      session[:guest_user_id] = u.id
      u
    end
    
    # Initializes an empty errors hash, before each action
    def initialize_errors_hash
      @errors = {}
    end

  end
end
