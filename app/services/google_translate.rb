class GoogleTranslate
 
  require 'net/http'
  require 'uri'
  require 'json'

  BASE_URL = "https://translation.googleapis.com/language/translate/v2"

  def initialize(api_key)
    @url = "#{BASE_URL}?key=#{api_key}"
    Rails.logger.info(@url)
  end

  def translate q, target="es", source="en"
  	params = {
	    "q": q,
	    "source": source,
	    "target": target,
      "format": "text"
    }
    self.send(params)
  end

 	## Send the Requests
  def send(params)
		uri = URI.parse(@url)
		header = {'Content-Type': 'text/json'}
		# Create the HTTP objects
		http = Net::HTTP.new(uri.host, uri.port)
	  http.use_ssl = true
	  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		request = Net::HTTP::Post.new(uri.request_uri, header)
		request.body = params.to_json
		# Send and unpack the request
		self.unpack(http.request(request))

  end #send
	
	# Get the Actual Translations
	def unpack(response)

		if response.code == '200'
			begin
				return JSON.parse(response.body)["data"]["translations"].first["translatedText"]  || ""
			rescue JSON::ParserError
				return ""
			end
		else
			return ""
		end
		
	end

end