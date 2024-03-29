source 'http://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

### DEFAULT RAILS GEMS ####################
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.1'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.21'
# Use Puma as the app server
gem 'puma'
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

### PRODUCTION APP RELATED #################
# Support for application.yml on AWS
gem 'figaro'
# Replacement for Heroku Scheduler on AWS
gem 'whenever', require: false
############################################

### LOGGING RELATED #######################
gem 'lograge'
gem 'lograge-sql'
############################################

### VIEWS & FORMATTING #####################
gem 'awesome_print'
gem 'haml-rails'
gem 'simple_form'
gem 'bootstrap-sass', '~> 3.3.6'
gem 'autoprefixer-rails'
gem 'jquery-ui-rails'
gem 'bootstrap-datepicker-rails'
gem 'chartkick' # For google charts
gem 'groupdate' # Extends chartkick functionality
gem 'phony_rails' # For normalizing phone numbers
gem 'jquery-datatables-rails', '~> 3.4.0'
############################################

### PAGINATION #############################
# gem 'kaminari', '~> 1.2.2'
gem 'pagy', '~> 5.10.1'
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
gem 'attr_encrypted', "~> 3.0.0" # For encrypting any column; used for external user booking password on UserBookingProfile
############################################


### i18n Tools #############################
gem 'rails-i18n'
gem 'simple_translation_engine', 
      github: 'camsys/simple_translation_engine', branch: 'lydia_translation_engine'
### SOAP Support ###########################
gem 'savon'
############################################


### FILE UPLOAD ############################
gem 'carrierwave-aws', '~> 1.5'
gem 'mini_magick' # For resizing images
gem 'remotipart', '~> 1.3', '>= 1.3.1'
gem 'aws-sdk-s3' # For uploading files to AWS S3 bucket, e.g. for translations json
############################################


### GEOSPATIAL #############################
gem 'rgeo'
gem "rgeo-proj4"
gem 'activerecord-postgis-adapter'
gem 'rgeo-shapefile'
gem 'geospatial-kml'
gem 'dbf'
gem 'rubyzip' # For unzipping shapefiles
gem 'leaflet-rails' # For embedding maps
############################################


### ASYNCHRONOUS API CALLS (e.g. to OTP) ###
gem 'em-http-request'
############################################


### Sending SMS messages via AWS ###########
gem 'aws-sdk-sns' 
############################################

### For creating db replicas and snapshots #
group :development, :qa do 
  gem 'aws-sdk-rds'
  gem 'aws-sdk-cloudwatch'
  gem 'aws-sdk-route53'
end

### ONECLICK MODULES #######################

# Loads names of modules to install into ENV variables
require './config/oneclick_modules.rb' if File.exists?('./config/oneclick_modules.rb')


# NOTE: For each OneClick module engine that can be included, set the `require`
# option to equal true if the ENV variable is set for that engine, and false if not
# e.g. ` gem 'some_engine', require: !!ENV["SOME_ENGINE"] `

# Download the oneclick_refernet gem, but only require it if env var is set
gem 'oneclick_refernet', github: 'camsys/oneclick_refernet', branch: 'derek_azure'
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

  gem 'factory_bot_rails'
  ##########################################
end

group :development do
  # Get a console in your browser in development
  gem "better_errors"
  gem "binding_of_caller"

  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem "letter_opener"

  gem 'rb-readline'
  gem "rdoc", "~> 6.3.0"
end


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Explicitly including these gems to fix a bug in Heroku
gem 'tzinfo'
gem 'tzinfo-data'