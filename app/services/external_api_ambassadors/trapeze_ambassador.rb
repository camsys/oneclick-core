class TrapezeAmbassador < BookingAmbassador

  attr_accessor :url, :user, :client, :client_id, :client_password
  
  # Calls super and then sets proper default for URL and Token
  def initialize(opts={})
    super(opts)
    @url ||= Config.trapeze_url
    @user ||= Config.trapeze_user
    @token ||= Config.trapeze_token
    @client = create_client(Config.trapeze_url, Config.trapeze_url, @user, @token)
    @client_id = opts[:client_id]
    @client_password = opts[:client_password]
  end

  # Returns symbol for identifying booking api type
  def booking_api
    :trapeze
  end

  def pass_validate_client_password
    begin
      response = @client.call(:pass_validate_client_password, message: {client_id: @client_id, password: @client_password})
    rescue
      return false
    end

    Rails.logger.info response.to_hash

    if response.to_hash[:pass_validate_client_password_response][:validation][:item][:code] == "RESULTOK"
      return true
    else
      return false
    end
  end

  protected

  # Create a Client
  def create_client(endpoint, namespace, username, password)

    client = Savon.client do
      endpoint endpoint
      namespace namespace
      basic_auth [username, password]
      convert_request_keys_to :camelcase
    end

    client

  end

end
