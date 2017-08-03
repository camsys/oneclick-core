# HTTP Request Bundler takes in URLs for external APIs, makes the requests
# asynchronously, and returns the categorized results in a useful way.

class HTTPRequestBundler
  attr_reader :requests, :successes, :errors

  def initialize
    @requests = {}
    @successes = {}
    @errors = {}
  end

  # Add an HTTP request to the bundler, for later processing
  def add(label, url, action=:get, opts={})
    @requests[label] = {
      url: url,
      action: action,
      opts: opts
    }
    
    return self
  end
  
  # Returns a hash of all responses
  def responses
    { successes: @successes, errors: @errors }
  end

  # Return the HTTP request response, based on the label used when passing in the request
  def response(label)
    ensure_response(label)
    response_for(label)
  end
  
  # Same as response, but always re-makes the call
  def response!(label)
    call!(label)
    response_for(label)
  end
  
  # Forces making call and overwriting response for given label
  def call!(label)
    make_calls(only: [label], overwrite: true)
    return self
  end
  
  # Returns true if a successful response was received for given call
  def success?(label)
    ensure_response(label)
    @successes.has_key?(label)
  end
  
  # Returns true if an error response was received for a given call
  def error?(label)
    ensure_response(label)
    @errors.has_key?(label)
  end

  # Make all of the HTTP requests that have been added to the bundler
  def make_calls(opts={})
    only = opts[:only] || @requests.keys
    except = opts[:except] || []
    overwrite = opts[:overwrite] || false # If set to true, will re-make all calls
    
    requests_to_make = (only - except)
    requests_to_make.reject! {|l| call_made?(l) } unless overwrite
    return false if requests_to_make.empty?

    EM.run do
      multi = EM::MultiRequest.new
      requests_to_make.each do |label|
        request = @requests[label]
        
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
        parse_responses(multi.responses)
        return responses
      end
    end

  end

  private
  
  # Checks if response has returned for given call;
  # if not (and if request is present), makes all calls
  def ensure_response(label)
    make_calls unless (response_for(label) || !@requests.has_key?(label))
  end
  
  # Retrieves response based on label from either successes or errors hash
  def response_for(label)
    @successes[label] || @errors[label]    
  end
  
  # Determines if a call has been made based on label
  def call_made?(label)
    @successes.has_key?(label) || @errors.has_key?(label)
  end

  # Parses the response bodies and stores them in successes and errors hashes under @responses
  def parse_responses(responses)
    update_responses(responses[:callback], @successes)
    update_responses(responses[:errback], @errors)
  end
  
  def update_responses(response_hash, storage_hash)
    response_hash.each do |label, resp|
      storage_hash[label] = (JSON.parse(resp.response) if resp.response.present?)
    end
  end
  
  # Parses success and error JSON into a hash
  def map_response_to_hash(response_obj)
    response_obj.map do |k,v| 
      [k, (JSON.parse(v.response) if v.response.present?)]
    end.to_h
  end

end
