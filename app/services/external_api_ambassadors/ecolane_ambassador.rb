class EcolaneAmbassador < BookingAmbassador

  attr_accessor :url, :external_id, :county, :dob, :ecolane_id, :system_id, :token
  require 'securerandom'

  def initialize(opts={})
    super(opts)
    @url ||= Config.ecolane_url
    @county = opts[:county]
    @dob = opts[:dob]
    @customer_number = opts[:ecolane_id]
    self.service ||= county_map[@county]
    self.system_id ||= service.booking_details[:external_id]
    self.token = service.booking_details[:token]
    @user ||= get_user
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

  ####################################################################
  ## Actual Calls to Ecolane 
  ####################################################################

  # Get a list of customers
  def search_for_customers terms={}
    url_options = "/api/customer/#{system_id}/search?"
    terms.each do |key,value|
      url_options += "&#{key}=#{value}"
    end
    response = send_request(@url+url_options)
    Hash.from_xml(response.body)
  end

  ##### 
  ## Send the Requests
  def send_request url, type='get', message=nil
    url.sub! " ", "%20"
    begin
      uri = URI.parse(url)
      case type.downcase
        when 'post'
          req = Net::HTTP::Post.new(uri.path)
          req.body = message
        when 'delete'
          req = Net::HTTP::Delete.new(uri.path)
        else
          req = Net::HTTP::Get.new(uri)
      end

      req.add_field 'X-ECOLANE-TOKEN', token
      req.add_field 'Content-Type', 'text/xml'

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      resp = http.start {|http| http.request(req)}
      return resp
    rescue Exception=>e
      Rails.logger.info("Sending Error")
      return false, {'id'=>500, 'msg'=>e.to_s}
    end
  end

  ###################################################################
  ## Helpers
  ###################################################################
  
  ### Does the ID/County/DOB match a single customer?
  def validate_passenger #customer_number, dob, system_id, token
    iso_dob = iso8601ify(@dob)
    if iso_dob.nil?
      return false
    end
    result = search_for_customers({"date_of_birth": iso_dob, "customer_number": @customer_number})
    if result["search_results"].nil?
      return false
    # If only one thing is returned, it comes as a hash.  Multilple items are returned as an array.
    # Since we want to see exactly 1 match, return true if this is a Hash.
    elsif result["search_results"]["customer"].is_a? Hash 
      return true
    else
      return false
    end
  end

  ### Find or Create User
  def get_user
    if validate_passenger
      user = nil
      ubp = UserBookingProfile.where(service: service, external_user_id: @customer_number).first_or_create do |profile|
        random = SecureRandom.hex(8)
        user = User.create!(
            email: "#{@customer_number}_#{@county}@ecolane_user.com", 
            password: random, 
            password_confirmation: random
          )
        profile.user = user
      end
      return ubp.user
    else
      return nil
    end
  end

  ### County Mapping ###
  def county_map
    services = Service.is_ecolane.published
    mapping = {}
    services.each do |service|
      counties = service.booking_details[:home_counties].split(',').map{ |c| c.strip }
      counties.each do |county|
        mapping[county] = service
      end
    end
    return mapping
  end

  def iso8601ify dob 
    dob = dob.split('/')
    unless dob.count == 3
      return nil
    end
    begin
      dob = Date.parse(dob[1] + '/' + dob[0] + '/' + dob[2]).strftime("%Y/%m/%d")
    rescue  ArgumentError
      return nil
    end
    Date.iso8601(dob.delete('/'))
  end

end
