module ApiErrorCatcher

  # Catch internal errors gracefully and send back a 500 response with JSON and proper headers
  def self.included(base)
    # Catches server errors so that response can be rendered as JSON with proper headers, etc.
    base.rescue_from Exception, with: :api_error_response
  end

  # Rescues 500 errors and renders them properly as JSON response
  def api_error_response(exception)
    exception.backtrace.each { |line| logger.error line }
    response = {
      error: { type: exception.class.name, message: exception.message }
    }
    render status: 500, json: response
  end

end
