class TrapezeAmbassador < BookingAmbassador

  attr_accessor :user, :client, :client_id, :client_password
  
  # Calls super and then sets proper default for URL and Token
  def initialize(opts={})
    super(opts)
    @url ||= Config.trapeze_url
    @user ||= Config.trapeze_user
    @token ||= Config.trapeze_token
    @client = Savon.client do
      endpoint @url
      namespace @url
      basic_auth [@user, @token]
      convert_request_keys_to :camelcase
    end
    @client_id = opts[:client_id]
    @client_password = opts[:client_password]
  end

  # Returns symbol for identifying booking api type
  def booking_api
    :trapeze
  end

  def pass_validate_client_password
    #begin
      response = @client.call(:pass_validate_client_password, message: {client_id: @client_id, password: @client_password})
    #rescue
    #  return false
    #end

    if response.to_hash[:pass_validate_client_password_response][:validation][:item][:code] == "RESULTOK"
      return true
    else
      return false
    end
  end


end
