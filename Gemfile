source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

### DEFAULT RAILS GEMS ####################
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.1'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.18'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
############################################


### Internal Views #########################
gem 'awesome_print'
gem 'haml-rails'
gem 'simple_form'
gem 'bootstrap-sass', '~> 3.2.0'
gem 'autoprefixer-rails'
gem 'jquery-ui-rails'
gem 'bootstrap-datepicker-rails'
gem 'chartkick' # For google charts
gem 'groupdate' # Extends chartkick functionality
############################################


### API & SERIALIZING ######################
# ActiveModel Serializers for serving JSON via the API
gem 'active_model_serializers', '~> 0.10.0'
gem 'rack-cors', require: 'rack/cors'
############################################


### USER AUTH ##############################
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'
gem 'devise'
gem 'simple_token_authentication', '~> 1.0' # For API Token Auth
gem 'cancancan'
gem 'rolify'
############################################


### i18n Tools #############################
gem 'rails-i18n'
gem 'simple_translation_engine', github: 'camsys/simple_translation_engine'
############################################


### FILE UPLOAD ############################
gem 'carrierwave', '~> 1.0'
gem 'mini_magick' # For resizing images
gem 'fog'
gem 'remotipart', '~> 1.3', '>= 1.3.1'
############################################


### GEOSPATIAL #############################
gem 'rgeo'
gem 'activerecord-postgis-adapter'
gem 'rgeo-shapefile'
gem 'dbf'
gem 'rubyzip' # For unzipping shapefiles
gem 'leaflet-rails' # For embedding maps
############################################


### ASYNCHRONOUS API CALLS (e.g. to OTP) ###
gem 'em-http-request'
############################################


# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  
  ### RSPEC & TESTING TOOLS ################
  gem 'rspec-rails', '~> 3.5'
  gem 'rails-controller-testing'
  gem 'shoulda-matchers', require: false
  gem 'factory_girl_rails'
  ##########################################
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
