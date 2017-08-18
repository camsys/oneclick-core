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
    response_body_for(label)
  end
  
  # Same as response, but always re-makes the call
  def response!(label)
    call!(label)
    response_body_for(label)
  end
  
  # Return the HTTP request status, based on the label used when passing in the request
  def status(label)
    ensure_response(label)
    response_status_for(label)
  end
  
  # Same as status, but always re-makes the call
  def status!(label)
    call!(label)
    response_status_for(label)
  end
  
  # Returns true if status call is a 200 code
  def success?(label)
    status(label)[0] == "2"
  end
  
  # Same as success?, but always remakes the call
  def success!(label)
    status!(label)[0] == "2"
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
    multi = !!opts[:multi] # Determines if the calls should be made one at a time or in parallel
    
    requests_to_make = (only - except)
    requests_to_make.reject! {|l| call_made?(l) } unless overwrite
    return false if requests_to_make.empty?

    multi ? make_multi_calls(requests_to_make) : make_single_calls(requests_to_make)

  end

  # private
  
  # Makes multiple EM HTTP Requests in parallel
  def make_multi_calls(requests_to_make)
    
    EM.run do
      
      multi = EM::MultiRequest.new
      requests_to_make.each do |req_label|        
        # Add an HTTP request to the multirequest, passing in the key as a label,
        # and pulling the appropriate action (e.g. get, post, etc.) and headers
        # from the body.
        multi.add(label, build_http_request(@requests[req_label]))
      end

      multi.callback do
        EventMachine.stop
        parse_responses(multi.responses)
      end
      
    end
    
    return responses
    
  end
  
  # Makes EM HTTP Requests one at a time
  def make_single_calls(requests_to_make)
    puts "MAKING SINGLE CALLS"
    
    requests_to_make.each do |req_label|
      
      EM.run do
        http_request = build_http_request(@requests[req_label])
        http_responses = { callback: {}, errback: {} }

        http_request.errback {
          puts "THERE WAS AN ERROR!"
          http_responses[:errback][req_label] = http_request
          parse_responses(http_responses)
          EM.stop
        }
        http_request.callback {
          puts "SUCCESS!"
          http_responses[:callback][req_label] = http_request
          parse_responses(http_responses)
          EM.stop
        }
        
      end
      
    end
    
    puts "RETURNING RESPONSES", responses.ai
    return responses
    
  end
    
    
  # Builds an EventMachine::HttpRequest object
  def build_http_request(request={})
    EM::HttpRequest.new(request[:url]).send(request[:action], request[:opts])
  end
  
  # Checks if response has returned for given call;
  # if not (and if request is present), makes all calls
  def ensure_response(label)
    make_calls unless (response_for(label) || !@requests.has_key?(label))
  end
  
  # Retrieves response based on label from either successes or errors hash
  def response_for(label)
    @successes[label] || @errors[label]
  end
  
  # Returns the response body
  def response_body_for(label)
    resp = response_for(label)
    begin
      JSON.parse(resp.try(:response))
    rescue JSON::ParserError
      { error: "Response Body not valid JSON" }
    end
  end
  
  # Returns the response status
  def response_status_for(label)
    response_for(label).try(:response_header).try(:[], "STATUS")
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
  
  def update_responses(responses, storage_hash)
    responses.each do |label, resp|
      storage_hash[label] = resp if resp.present?
    end
  end

end
