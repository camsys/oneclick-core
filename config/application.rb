require_relative 'boot'

require 'rails/all'
# require 'active_record/connection_adapters/postgis_adapter/railtie'
# require "./lib/middleware/catch_json_parse_errors.rb"
require './app/controllers/concerns/json_response_helper.rb'


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OneclickCore
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.time_zone = ENV['TIME_ZONE'] || 'Eastern Time (US & Canada)'
    config.i18n.available_locales = [:en, :es]
    config.i18n.default_locale = :en
    
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

    # Sends back appropriate JSON 400 response if a bad JSON request is sent.
    config.middleware.insert_before Rack::Head, JsonResponseHelper::CatchJsonParseErrors


    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
    
    # Loads application.yml file for local ENV variables
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exists?(env_file)
      
      require './config/oneclick_modules.rb' # Loads names of installed modules into ENV variables
    end


  end
end
