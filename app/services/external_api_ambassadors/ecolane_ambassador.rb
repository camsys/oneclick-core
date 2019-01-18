class EcolaneAmbassador < BookingAmbassador

  attr_accessor :url, :external_id
  
  # Calls super and then sets proper default for URL and Token
  def initialize(opts={})
    super(opts)
    @url ||= Config.ecolane_url
  end

  #####################################################################
  ## Top-level required methods in order for BookingAmbassador to work
  #####################################################################
  # Returns symbol for identifying booking api type
  def booking_api
    :ecolane
  end

  def authentic_provider?
    true
  end

end
