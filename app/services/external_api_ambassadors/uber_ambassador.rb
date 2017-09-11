class UberAmbassador

  attr_accessor :trip, :http_request_bundler

  # Initialize with a trip an HTTP request bundler, and list of services or cities
  def initialize(trip, http_request_bundler)
    @trip = trip
    @uber_api_service = UberApiService.new(Config.uber_token)
    @http_request_bundler = http_request_bundler

    # add http calls to bundler based on services
    request = prepare_http_requests
    @http_request_bundler.add(request[:label], request[:url], request[:action], request[:options])#'uber_estimates_fares', request[:url], :get, headers = {})
  end

    # Prepares HTTP requests based on available services, to pass to HTTP Request Bundler
  def prepare_http_requests
    {
      label: :uber_prices,
      url: @uber_api_service.estimates_price_url([@trip.destination.lat, @trip.destination.lng], [@trip.origin.lat, @trip.destination.lng]),
      action: :get,
      options: {
        head: @uber_api_service.headers 
      }
    }
  end

  def cost product="uberX"
    result = @uber_api_service.price(product, @http_request_bundler.response(:uber_prices))
    return result[:price], result[:product_id]
  end  

end
