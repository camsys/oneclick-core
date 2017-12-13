class TrapezeAmbassador < BookingAmbassador
  
  # Calls super and then sets proper default for URL and Token
  def initialize(opts={})
    super(opts)
    @url ||= Config.trapeze_url
    @user ||= Config.trapeze_user
    @trapeze ||= Config.trapeze_token
  end

  # Returns symbol for identifying booking api type
  def booking_api
    :trapeze
  end

  # Returns boolean true/false if user is a RidePilot user
  def authenticate_user?
    authenticate_customer == "200 OK"
  end

  def authenticate_customer    
    label = request_label(:authenticate_customer, customer_id)
        
    @http_request_bundler.add(
      label, 
      @url + "/authenticate_customer", 
      :get,
      head: headers,
      query: { provider_id: provider_id, customer_id: customer_id, customer_token: customer_token }
    ).status!(label)
  end


end
