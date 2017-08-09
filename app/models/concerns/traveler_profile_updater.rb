# Traveler Profile Updater, Built for API V1 but used for V2 as well
# For inclusion in User model

module TravelerProfileUpdater
  
  def update_profile(params={})
    return true if params.blank?
    update_basic_attributes params[:attributes] unless params[:attributes].nil?
    update_eligibilities params[:characteristics] unless params[:characteristics].nil?
    update_eligibilities params[:eligibilities] unless params[:eligibilities].nil?
    update_accommodations params[:accommodations] unless params[:accommodations].nil?
    update_preferred_modes params[:preferred_trip_types] unless params[:preferred_trip_types].nil?
    update_preferred_modes params[:preferred_modes] unless params[:preferred_modes].blank? #This is depracated after api/v1. Preferred Modes are updated as part of attributes
    update_booking_profile params[:booking]
    return true
  end

  def update_basic_attributes params={}
    params.each do |key, value|
      case key.to_sym
        when :first_name
          self.first_name = value
        when :last_name
          self.last_name = value
        when :email
          self.email = value
        when :lang, :preferred_locale
          self.preferred_locale = Locale.find_by(name: value) || self.locale
        when :preferred_trip_types, :preferred_modes
          self.preferred_trip_types = value
        when :password 
          self.password = value
        when :password_confirmation
          self.password_confirmation = value
      end
    end
    self.save!
  end

  def update_eligibilities params={}
    params.each do |code, value|
      eligibility = Eligibility.find_by(code: code)
      if eligibility
        ue = self.user_eligibilities.where(eligibility: eligibility).first_or_create
        ue.value = value.to_bool
        ue.save
      end
    end
  end

  def update_accommodations params={}
    user_accommodations = self.accommodations
    params.each do |code, value|
      accommodation = Accommodation.find_by(code: code)
      if accommodation
        user_accommodations.delete(accommodation)
        if value.to_bool
          user_accommodations << accommodation
        end
      end
    end

    self.accommodations = user_accommodations

  end

  def update_preferred_modes params
    self.preferred_trip_types = params.map{ |m| m.to_s.gsub('mode_',"")}
    self.save
  end
  
  # Creates or updates a UserBookingProfile based on the passed params
  def update_booking_profile(params_array)
    params_array.each do |params|
      service = Service.find_by(id: params[:service_id])
      profile = self.booking_profile_for(service) || self.booking_profiles.build(service: service)
      profile.booking_api = params[:booking_api] || "ride_pilot" || profile.booking_api
      details_hash = profile.details || {}
      details_hash[:id] = params[:user_name] || details_hash[:id]
      details_hash[:token] = params[:password] || details_hash[:token]
      profile.details = details_hash
      puts "BOOKING_PROFILE", profile.ai
      profile.authenticate? ? profile.save : false
    end
  end
  
end
