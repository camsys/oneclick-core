# initalize app
require './config/environment.rb'
require "rubygems"

require 'json'
require 'logger'
require 'mysql2'

# get config and version info
config = JSON.parse(File.read('prod_data_utils/config.json'))
version = Rails.application.config.version
app = config['app']['app']

# configure logger
system("mkdir -p prod_data_check/logs")
logger = Logger.new("prod_data_check/logs/backup_#{version}.log", "daily")
logger.level = Logger::DEBUG

logger.info "-------------------------------------------------------------------------------------------------------------"
logger.info "---------------- start backup for #{app} #{version} on #{DateTime.now.to_s} ------------------"

require_relative "db_backup_utils"
db_util = DbBackupUtils.new(config, version, ENV['RAILS_ENV'], logger: logger)
db_util.run

logger.info "---------------- finished backup for #{app} #{version} on #{DateTime.now.to_s} ------------------"
logger.info "--------------------------------------------------------------------------------------------------------------"
