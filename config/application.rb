require_relative 'boot'

require 'rails/all'
# require 'active_record/connection_adapters/postgis_adapter/railtie'
# require "./lib/middleware/catch_json_parse_errors.rb"
require './app/controllers/concerns/json_response_helper.rb'
require './app/services/api_request_logger.rb' # For logging API controller requests to DB
# require './lib/api_request_logger.rb' # For logging API controller requests to DB

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OneclickCore
  class Application < Rails::Application
    # Init Log file
    puts "Passenger/ Puma starting up in #{Rails.env} mode"

    # I18n Internationalization
    config.i18n.default_locale = (ENV['DEFAULT_LOCALE'] || "en").try(:to_sym)
    config.i18n.available_locales = (ENV['AVAILABLE_LOCALES'] || "en").split(',').compact.map(&:strip).map(&:to_sym)
    I18n.available_locales = (ENV['AVAILABLE_LOCALES'] || "en").split(',').compact.map(&:strip).map(&:to_sym)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    
    # Load model sub-classes and other custom folders
    config.autoload_paths += %W(#{config.root}/app/models/service_types)
    config.autoload_paths += %W(#{config.root}/app/models/agency_types)
    config.autoload_paths += %W(#{config.root}/app/models/booking_types)
    config.autoload_paths += %W(#{config.root}/app/services/external_api_ambassadors)

    # Set default CORS settings
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*' # /http:\/\/localhost:(\d*)/
        resource '*',
          # headers: ['Origin', 'X-Requested-With', 'Content-Type', 'Accept',
          #   'Authorization', 'X-User-Token', 'X-User-Email',
          #   'Access-Control-Request-Headers', 'Access-Control-Request-Method'
          # ],
          headers: :any, # fixes CORS errors on OPTIONS requests
          methods: [:get, :post, :put, :delete, :options]
        end
    end
    # Likely needed to allow forwarding when a CNAME DNS is not used.
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'ALLOWALL'
    }

    # Sends back appropriate JSON 400 response if a bad JSON request is sent.
    config.middleware.insert_before Rack::Head, JsonResponseHelper::CatchJsonParseErrors


    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
    
    # Loads application.yml file for local ENV variables
    config.before_configuration do

      # Load different ENV files based on what the environment is.
      env_files = []
      env_files << File.join(Rails.root, 'config', 'local_env.yml.travis')
      env_files << File.join(Rails.root, 'config', 'local_env.yml') if Rails.env.development?
      env_files << File.join(Rails.root, 'config', 'test_env.yml') if Rails.env.test?

      env_files.each do |env_file|
        YAML.load(File.open(env_file)).each do |key, value|
          ENV[key.to_s] = value
        end if File.exists?(env_file)
      end
      
      # Loads names of installed modules into ENV variables
      require './config/oneclick_modules.rb' if File.exists?('./config/oneclick_modules.rb')
    end


    # Logs all API requests to DB. See app/services/api_request_logger.rb for details.
    config.api_request_logger = ApiRequestLogger.new('/api', {
      exclude_controllers: [],
      exclude_actions: {},
      log_to_db: true
    })
    config.api_request_logger.start

    config.admin_console_logger = ApiRequestLogger.new(%w[/admin /], {
      exclude_controllers: [],
      exclude_actions: {},
      log_to_db: false
    })
    config.admin_console_logger.start
    # Enable app logging when applicable
    if ENV["RAILS_LOG_TO_STDOUT"].present?
      # Create logger for logging database changes(creating/ altering/ dropping tables)
      # Should largely be okay to build this here since this is only tracking db migrations
      # and rake tasks run in development by default
      config.db_logger = ActiveSupport::Logger.new("log/db_changes.log")
      config.logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")
    end


    config.time_zone = ENV['TIME_ZONE'] || 'Eastern Time (US & Canada)'


  end
end
