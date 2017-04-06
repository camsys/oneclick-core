# HTTP Request Bundler takes in URLs for external APIs, makes the requests
# asynchronously, and returns the categorized results in a useful way.

class HTTPRequestBundler
  attr_reader :requests, :responses

  def initialize
    @requests = {}
    @responses = nil
  end

  # Add an HTTP request to the bundler, for later processing
  def add(label, url, action=:get)
    @requests[:label] = {
      request: EM::HttpRequest.new(url),
      action: action
    }
  end

  # Return the HTTP request response, based on the label used when passing in the request
  def response(label)
    make_calls unless @responses
    return nil unless @responses
    @responses[:successes][label] || @responses[:errors][label]
  end

  # Make all of the HTTP requests that have been added to the bundler
  def make_calls
    return false if @requests.empty?
    EM.run do
      multi = EM::MultiRequest.new
      @requests.each do |label, body|
        multi.add label, body[:request].send(body[:action])
      end

      multi.callback do
        EventMachine.stop
        @responses = parse_responses(multi.responses)
        return @responses
      end
    end
  end

  private

  # Parses the response bodies and stores them in successes and errors hashes under @responses
  def parse_responses(responses)
    {
      successes: responses[:callback].map {|k,v| [k, JSON.parse(v.response)]}.to_h,
      errors: responses[:errback].map {|k,v| [k, JSON.parse(v.response)]}.to_h
    }
  end

end
