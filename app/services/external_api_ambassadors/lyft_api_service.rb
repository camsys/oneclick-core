class LyftApiService

  attr_accessor :token

  BASE_URL = "https://api.lyft.com/v1"

  #https://api.lyft.com/v1/ridetypes?lat=37.7763&lng=-122.3918'


  def initialize(token)
    @token = token
  end

  # Returns a TFF url based on passed params
  def price_url(to, from)
    #BASE_URL + "/estimates/price?start_latitude=#{from[0]}&start_longitude=#{from[1]}&end_latitude=#{to[0]}&end_longitude=#{to[1]}"
    #BASE_URL + "/ridetypes?lat=37.7763&lng=-122.3918"
    BASE_URL + "/cost?start_lat=#{from[0]}&start_lng=#{from[1]}&end_lat=#{to[0]}&end_lng=#{to[1]}"#&ride_type=lyft"

  end

  def headers
    {"Authorization": "Bearer #{@token}"}
  end

  def price(product, response)
    puts response.ai 

    unless response && response['cost_estimates'].present?
      return {price_quote_id: nil, price: nil}
    end

    price = response['cost_estimates'].detect{ |price| price["ride_type"] == product }
    return {price_quote_id: price["price_quote_id"], price: price["estimated_cost_cents_max"].to_f/100.0}
  end

end