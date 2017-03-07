require_relative 'boot'

require 'rails/all'
# require 'active_record/connection_adapters/postgis_adapter/railtie'

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

  end
end
