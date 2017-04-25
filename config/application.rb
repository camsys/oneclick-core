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

    config.time_zone = 'Eastern Time (US & Canada)'
    config.i18n.available_locales = [:en, :es]
    config.i18n.default_locale = :en

    # Load different Service Types
    config.autoload_paths += %W(#{config.root}/app/models/services)

    # Set default CORS settings
    # config.action_dispatch.default_headers = {
    #   'Access-Control-Allow-Origin' => '*',
    #   'Access-Control-Allow-Methods' => 'POST, PUT, DELETE, GET, OPTIONS',
    #   'Access-Control-Request-Method' => '*',
    #   'Access-Control-Allow-Headers' => 'Origin, X-Requested-With,
    #     Content-Type, Accept, Authorization, X-User-Token, X-User-Email'
    # }
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*',
          headers: 'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-Token, X-User-Email',
          methods: [:get, :post, :put, :delete, :options]
      end
    end

    # Sends back appropriate JSON 400 response if a bad JSON request is sent.
    config.middleware.insert_before Rack::Head, JsonResponseHelper::CatchJsonParseErrors

  end
end
