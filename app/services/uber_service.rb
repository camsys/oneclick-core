class UberService

  attr_accessor :token

  BASE_URL = "https://api.uber.com/v1.2"

  def initialize(token)
    @token = token
  end

  # Returns a TFF url based on passed params
  def estimates_price_url(to, from)
    BASE_URL + "/estimates/price?start_latitude=#{from[0]}&start_longitude=#{from[1]}&end_latitude=#{to[0]}&end_longitude=#{to[1]}"
  end

  # Unpacks the TFF response into a useful hash.
  def unpack_response(response_body)
    if response_body.nil?
      return {code: 500, prices: nil, message: "No Uber Data"}
    elsif not response_body['prices'] or response_body['prices'].count == 0
      return {code: 404, prices: nil}
    else
      return {code: 200, prices: response_body['prices']}
    end
  end

  def estimates_price to, from
    url = estimates_price_url(to, from)
    Rails.logger.info "Calling Uber Fare Estimate: url: #{url}"
    resp = nil
    begin
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      
      #Add Headers
      request["Authorization"] = "Token #{@token}"
      response = http.request(request)
    rescue Exception=>e
      puts e.ai 
      return
    end
    body = JSON.parse(response.body)
    return unpack_response(body)
  end

end