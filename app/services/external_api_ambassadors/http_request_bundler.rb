# HTTP Request Bundler takes in URLs for external APIs, makes the requests
# asynchronously, and returns the categorized results in a useful way.

class HTTPRequestBundler
  attr_reader :requests, :responses

  def initialize
    @requests = {}
    @responses = nil
  end

  # Add an HTTP request to the bundler, for later processing
  def add(label, url, action=:get, opts={})
    @requests[label] = {
      url: url,
      action: action,
      opts: opts
    }
  end

  # Return the HTTP request response, based on the label used when passing in the request
  def response(label)
    ensure_responses
    @responses[:successes][label] || @responses[:errors][label]
  end
  
  # Returns true if a successful response was received for given call
  def success?(label)
    ensure_responses
    @responses[:successes].has_key?(label)
  end
  
  # Returns true if an error response was received for a given call
  def error?(label)
    ensure_responses
    @responses[:errors].has_key?(label)
  end

  # Make all of the HTTP requests that have been added to the bundler
  def make_calls
    return false if @requests.empty?
    EM.run do
      multi = EM::MultiRequest.new
      @requests.each do |label, request|
        # Add an HTTP request to the multirequest, passing in the key as a label,
        # and pulling the appropriate action (e.g. get, post, etc.) and headers
        # from the body.
        multi.add(label, 
          EM::HttpRequest.new(request[:url])
          .send(request[:action], request[:opts])
        )
      end

      multi.callback do
        EventMachine.stop
        @responses = parse_responses(multi.responses)
        return @responses
      end
    end

  end

  private
  
  # Makes calls and sets up a blank response object if calls fail
  def ensure_responses
    make_calls unless @responses
    @responses ||= { successes: {}, errors: {} }
  end

  # Parses the response bodies and stores them in successes and errors hashes under @responses
  def parse_responses(responses)
    {
      successes: map_response_to_hash(responses[:callback]),
      errors: map_response_to_hash(responses[:errback])
    }
  end
  
  # Parses success and error JSON into a hash
  def map_response_to_hash(response_obj)
    response_obj.map do |k,v| 
      [k, (JSON.parse(v.response) if v.response.present?)]
    end.to_h
  end

end
