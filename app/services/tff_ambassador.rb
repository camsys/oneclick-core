class TFFAmbassador

  attr_accessor :trip, :fares, :services, :http_request_bundler

  # Initialize with a trip and an array of trip types
  def initialize(trip, services, http_request_bundler)
    @trip = trip
    @tff = TFFService.new(Config.tff_api_key)
    @services = services
    @fares = {}
    @http_request_bundler = http_request_bundler

    # add http calls to bundler based on services
    prepare_http_requests.each do |request|
      @http_request_bundler.add(request[:label], request[:url], request[:action])
    end
  end

  # Get the Fare for a Single Service.
  # First Check to see if we already called TFF.
  def fare service
    city_label = city_to_label(service.taxi_fare_finder_id)
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
    @http_request_bundler.make_calls unless @http_request_bundler.response(city_label)
    response = @tff.unpack_response(@http_request_bundler.response(city_label))
    if response[:code] == 200
      return response[:fare]
    else
      Rails.logger.info response[:message]
      return nil
    end
  end

  # Go through every taxi service in the trip and set the fare.
  def set_taxi_fares
    @trip.itineraries.taxi_itineraries.each do |itin|
      itin.cost = fare(itin.service)
      itin.save
    end
  end

  private

  # Prepares HTTP requests based on available services, to pass to HTTP Request Bundler
  def prepare_http_requests
    cities = @services.map { |s| s.taxi_fare_finder_id }.uniq
    cities.map do |city|
      {
        label: city_to_label(city),
        url: get_request_url(city),
        action: :get
      }
    end
  end

  # Converts a TFF city code into a symbol for labeling
  def city_to_label(city)
    ("tff_" + city).parameterize.underscore.to_sym
  end

end
