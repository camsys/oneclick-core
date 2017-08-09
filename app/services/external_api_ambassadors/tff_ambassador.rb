class TFFAmbassador

  attr_accessor :trip, :fares, :cities, :http_request_bundler

  # Initialize with a trip an HTTP request bundler, and list of services or cities
  def initialize(trip, http_request_bundler, options={})
    @trip = trip
    @tff = TFFService.new(Config.tff_api_key)
    @services = options[:services] || []
    @cities = options[:cities] || []
    @cities = (@cities + cities_from_services(@services)).uniq
    @fares = {}
    @http_request_bundler = http_request_bundler

    # add http calls to bundler based on services
    prepare_http_requests.each do |request|
      @http_request_bundler.add(request[:label], request[:url], request[:action])
    end if @cities
  end

  # Get the Fare for a Single Service or City
  # First Check to see if we already called TFF.
  def fare service_or_city
    tff_city = service_or_city.is_a?(Service) ? tff_city_for(service_or_city) : service_or_city
    return nil unless tff_city
    city_label = city_to_label(tff_city)
    return @fares[city_label] if @fares[city_label]

    fare = retrieve_fare(city_label)
    @fares[city_label] = fare
    return fare
  end

  # Gets a fare request url
  def get_request_url(city)
    to = [@trip.destination.lat, @trip.destination.lng]
    from = [@trip.origin.lat, @trip.origin.lng]
    @tff.fare_url(city, to, from)
  end

  # Get fare from TFF response
  def retrieve_fare(city_label)
    response = @tff.unpack_response(@http_request_bundler.response(city_label))
    if response[:code] == 200
      return response[:fare]
    else
      Rails.logger.info response[:message]
      return nil
    end
  end

  private

  # Pulls city codes from services
  def cities_from_services(services)
    services.map do |svc|
      svc.fare_details && svc.fare_details[:taxi_fare_finder_city]
    end.compact
  end

  # Prepares HTTP requests based on available services, to pass to HTTP Request Bundler
  def prepare_http_requests
    @cities.map do |city|
      {
        label: city_to_label(city),
        url: get_request_url(city),
        action: :get
      }
    end
  end

  # Converts a TFF city code into a symbol for labeling
  def city_to_label(city)
    ("tff_" + city.to_s).parameterize.underscore.to_sym
  end

  # Gets a service's TFF city if it's set, or returns nil if not
  def tff_city_for(service)
    return nil unless service.fare_structure == "taxi_fare_finder"
    service.fare_details && service.fare_details[:taxi_fare_finder_city]
  end

end
