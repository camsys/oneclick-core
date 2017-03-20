class TFFAmbassador

  # Initialize with a trip and an array of trip types
  def initialize(trip, service)
    @trip = trip
    @service = service
    @tff = TFFService.new(Config.tff_api_key)
    @responses = {}
  end

  def get_fare(trip, service)
  end

end
