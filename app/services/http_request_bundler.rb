# HTTP Request Bundler takes in URLs for external APIs, makes the requests
# asynchronously, and returns the categorized results in a useful way.

class HTTPRequestBundler
  attr_reader :responses

  def initialize
    @requests = []
    @responses = {successes: [], errors: []}
  end

  def add(label, url, action=:get)
    @requests << {
      label: label,
      request: EM::HttpRequest.new(url),
      action: action
    }
  end

  def make_calls
    EM.run do
      multi = EM::MultiRequest.new
      @requests.each_with_index do |request, i|
        multi.add request[:label], request[:request].send(request[:action])
      end

      multi.callback do
        EventMachine.stop
        @responses[:successes] = multi.responses[:callback]
        @responses[:errors] = multi.responses[:errors]
        return @responses
      end
    end
  end

end
