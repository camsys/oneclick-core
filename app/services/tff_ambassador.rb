class TFFAmbassador
  attr_accessor :trip, :service

  # Initialize with a trip and an array of trip types
  def initialize(trip, service)
    @trip = trip
    @service = service
    @tff = TFFService.new(Config.tff_api_key)
    @responses = {}
  end

  def fare(trip, service)
    fare to, from, city
  end

  def set_taxi_fares trip
    
  end

end
