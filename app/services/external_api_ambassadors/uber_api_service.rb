class UberApiService

  attr_accessor :token

  BASE_URL = "https://api.uber.com/v1.2"

  def initialize(token)
    @token = token
  end

  # Returns a TFF url based on passed params
  def estimates_price_url(to, from)
    BASE_URL + "/estimates/price?start_latitude=#{from[0]}&start_longitude=#{from[1]}&end_latitude=#{to[0]}&end_longitude=#{to[1]}"
  end

  def headers
    {"Authorization": "Token #{@token}"}
  end

  def price(product, response)
    unless response && response['prices']
      return {product_id: nil, price: nil}
    end

    puts response.ai 
    price = response['prices'].detect{ |price| price["display_name"] == product }
    return {product_id: price["product_id"], price: price["high_estimate"]}
  end

end
