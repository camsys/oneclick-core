
# Creates an ApiRequestLogger, configured to log all requests to Api:: namespaced
# controllers. May add controllers and/or specific actions to exclude, if desired.
# See api_request_logger.rb for more details.

if(ENV['LOG_API_REQUESTS'] == "true")
  puts "LOGGING API REQUESTS"
  
  ApiRequestLogger.new(
    exclude_controllers: [],
    exclude_actions: {}
  ).start
end
