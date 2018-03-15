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
    
    # By default, will attempt to set guest traveler if guest headers are sent
    before_action :set_guest_traveler, if: :guest_headers?

    ### TOKEN AUTHENTICATION NOTES ###
    # By default: Will attempt to authenticate user and set @traveler if
    # X-User-Email and X-User-Token headers are passed, but will not throw
    # an error if authentication fails. If an existing guest's email is passed, 
    # will set that guest user as traveler.
    #
    # Use before_action :require_authentication to require authentication,
    # and respond with a 401 if it fails.
    #
    # Use before_action :attempt_authentication to attempt authentication, throw
    # a 401 if it fails, and otherwise ensure that a guest traveler is set
    #
    # Use before_action :ensure_traveler to make sure that a traveler is set,
    # either guest or registered, but not throw a 401 error if user can't be authenticated
    #
    # To perform an action only if authentication was successful, use the
    # authentication_successful? boolean method.
    ##################################

    # Renders a 401 failure response if authentication was not successful
    # Disallows guest traveler auth
    def require_authentication
      render_failed_auth_response unless authentication_successful? # render a 401 error
    end
    
    # If non-guest email and token are provided, attempt to token authenticate and 
    # render a 401 if failed. Allows guest travelers
    def attempt_authentication
      if auth_headers.present? && auth_headers[:email] && !guest_headers?
        require_authentication
      end
      
      # If no authentication is provided, create a new guest user
      # ensure_traveler
    end
    
    # Ensure that a user object is created and loaded as @traveler
    def ensure_traveler
      set_traveler
      create_guest_user if @traveler.nil?
      @traveler
    end
    
    # Sets guest traveler based on auth email only
    def set_guest_traveler
      return nil unless auth_headers.present?
      @traveler = User.guests.find_by(email: auth_headers[:email]) || @traveler
    end
    
    # Sets registered traveler based on complete auth headers
    def set_registered_traveler
      return nil unless auth_headers.present? && auth_headers[:email] && auth_headers[:authentication_token]
      @traveler = User.find_by(email: auth_headers[:email], 
                               authentication_token: auth_headers[:authentication_token]) ||
                  @traveler
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
    
    # Sets the @traveler variable to the current api user -- registered or guest
    def set_traveler
      puts "SETTING TRAVELER", @traveler
      set_guest_traveler
      puts @traveler
      set_registered_traveler
      puts @traveler
    end
    
    # dummy action for testing API Controller
    def test
      if params[:before_action]
        self.send(params[:before_action])
      end
    end
    
    protected
    
    # Returns true if auth header email is a guest email
    def guest_headers?
      email = auth_headers[:email]
      email && GuestUserHelper.new.is_guest_email?(email)
    end

    # Actions to take after successfully authenticated a user token.
    # This is run automatically on successful token authentication
    def after_successful_token_authentication
      set_traveler
    end

    # Finds the User associated with auth headers.
    def current_api_user
      User.find_by(auth_headers) if auth_headers.present? 
    end

    # Returns a hash of authentication headers, or an empty hash if not present
    def auth_headers
      {
        email: request.headers["X-User-Email"], 
        authentication_token: request.headers["X-User-Token"]
      }
    end

    # Renders a failed user auth response
    def render_failed_auth_response
      render status: 401,
        json: json_response(:fail, data: {user: "Valid user email and token must be present."})
    end

    # Returns true if authentication of a registered traveler (not a guest) has successfully completed
    def authentication_successful?
      auth_headers.present? && 
      auth_headers[:authentication_token].present? && 
      @traveler.present?
    end
    
    
    ### RESPONSE METHODS ###
    # Based on JSend Specification
    
    # Constructs default serializer options hash based on current locale
    def default_serializer_options
      {
        include: ['*.*'],  # By default, serialize 2 levels of nesting
        scope: {locale: @locale } # By default, pass locale to serializer scope
      }
    end
    
    # Renders a successful response, passing along a given object as data
    # If the serializer option is passed, will attempt to serialize the data
    # with the passed serializer
    def success_response(data={}, opts={})
      status = opts.delete(:status) || 200 # Status code is 200 by default
      
      # Set serializer options by starting with the default options and then overwriting
      # or amending with any additional options passed.
      serializer_opts = default_serializer_options.merge(opts.delete(:serializer_opts) || {})
      
      @root = opts.delete(:root) || nil # By default, no root key
      @serializer = opts.delete(:serializer) || nil # If specifying serializer
            
      # Check if an ActiveRecord object or collection was passed, and if so, serialize it
      if data.is_a?(ActiveRecord::Relation)
        data = package_collection(data, serializer_opts)
      elsif data.is_a?(Array) # If it's an array of record objects, rather than a collection
        data = data.map { |rec| package_record(rec, serializer_opts) }
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
      puts "CREATING GUEST USER!"
      u = GuestUserHelper.new.build_guest
      u.skip_confirmation! #Don't send confirmation emails to the fake guest users
      u.save!(:validate => false)
      @traveler = u
      session[:guest_user_id] = u.id # DEPRECATE? What is this?
      u
    end
    
    # Initializes an empty errors hash, before each action
    def initialize_errors_hash
      @errors = {}
    end

  end
end
