
class TFFService

  attr_accessor :api_key

  BASE_URL = "https://api.taxifarefinder.com/"

  def initialize(api_key)
    @api_key = api_key
  end

  def fare city, to, from
    entity = '&entity_handle=' + city
    api_key = '?key=' + @api_key
    fare_options = "&origin=" + to[0].to_s + ',' + to[1].to_s + "&destination=" + from[0].to_s + ',' + from[1].to_s

    url = BASE_URL + 'fare' + api_key + entity + fare_options
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

    if body['status'] != 'OK'
      return {code: 500, status: body['status'], message: body['explanation']}
    else
      return {code: 200, status: "Success", fare: body['metered_fare']}
    end
  end

end