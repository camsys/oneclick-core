class TFFService

  attr_accessor :api_key

  BASE_URL = "https://api.taxifarefinder.com/"

  def initialize(api_key)
    @api_key = api_key
  end

  # Returns a TFF url based on passed params
  def fare_url(city, to, from)
    entity = '&entity_handle=' + city
    api_key = '?key=' + @api_key
    fare_options = "&origin=" + to[0].to_s + ',' + to[1].to_s + "&destination=" + from[0].to_s + ',' + from[1].to_s

    BASE_URL + 'fare' + api_key + entity + fare_options
  end

  # Unpacks the TFF response into a useful hash.
  def unpack_response(response_body)
    if response_body.nil?
      return {code: 500, status: 'Error', message: "No Taxi Fare Finder response available"}
    elsif response_body['status'] != 'OK'
      return {code: 500, status: response_body['status'], message: response_body['explanation']}
    else
      return {code: 200, status: "Success", fare: response_body['metered_fare']}
    end
  end

  def fare city, to, from
    url = fare_url(city, to, from)

    Rails.logger.info "Calling Taxi Fare Finder: url: #{url}"

    resp = nil
    begin
      timeout(3) do
        resp = Net::HTTP.get_response(URI.parse(url))
      end
      if resp.nil?
        return nil
      end
    rescue Exception=>e
      return
    end
    body = JSON.parse(resp.body)

    return unpack_response(body)
  end

end
