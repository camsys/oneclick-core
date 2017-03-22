class TFFAmbassador

  attr_accessor :trip, :fares

  # Initialize with a trip and an array of trip types
  def initialize(trip)
    @trip = trip
    @tff = TFFService.new(Config.tff_api_key)
    @fares = {}
  end

  # Get the Fare for a Single Service.
  # First Check to see if we already called TFF.
  def fare service
    city = service.taxi_fare_finder_id
    return @fares[city] if @fares[city]
    
    to = [@trip.destination.lat, @trip.destination.lng]
    from = [@trip.origin.lat, @trip.origin.lng]

    fare = retrieve_fare(city, to, from)
    @fares[city] = fare
    return fare 
  end

  # Get Fare from TFF.
  def retrieve_fare city, to, from 
    response = @tff.fare(city, to, from)
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

end
