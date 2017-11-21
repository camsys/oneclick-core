
# Creates an ApiRequestLogger, configured to log all requests to Api:: namespaced
# controllers. May add controllers and/or specific actions to exclude, if desired.
# See api_request_logger.rb for more details.
ApiRequestLogger.new(
  exclude_controllers: [],
  exclude_actions: {}
).start
