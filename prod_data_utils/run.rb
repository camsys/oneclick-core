# initalize app
require './config/environment.rb'
require "rubygems"

require 'json'
require 'logger'
require 'mysql2'

# This script does following things:
# 1. create a read replica off target database
# 2. establish application connection to the read replica db
# 3. run necessary database and data migration tasks
# 4. run deployment specific custom tasks
# 5. kill the replica instance after running data checks

# get config and version info
config = JSON.parse(File.read('prod_data_utils/config.json'))
version = config['version'].strip
app = config['app']['app']

# configure logger
system("mkdir -p logs")
logger = Logger.new("prod_data_utils/logs/prod_data_utils_#{version}.log", "daily")
logger.level = Logger::DEBUG 

logger.info "-------------------------------------------------------------------------------------------------------------"
logger.info "---------------- start data check for #{app} v#{version} on #{DateTime.now.to_s} ------------------"

if version == Rails.application.config.version
  puts 'We are creating a db replica of production'
  # Create db replica and establish db connection to replica instance
  require_relative "db_replica_utils"
  db_util = DbReplicaUtils.new(config, ENV['RAILS_ENV'], logger: logger)
  db_util.run

  # re-connect to new db
  ActiveRecord::Base.connection.reconnect!
else
  puts 'Not creating a db replica of production'
end

logger.info "---------------- finish data check for #{app} v#{version} on #{DateTime.now.to_s} ------------------"
logger.info "--------------------------------------------------------------------------------------------------------------"

