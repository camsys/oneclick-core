module ImportTaskHelpers
  
  # Unpacks the rake task arguments, constructs a url, calls it, and returns the response
  def get_export_data(args, route)
    url = export_url(args['host'], route, args['token'])
    puts "Calling: #{url}"
    JSON.parse(open(url).read)
  end
  
  # Constructs a OneClick Export API URL from host, route string, and token
  def export_url(host, route, token)
    "#{host}/export/#{route}?token=#{token}"
  end
  
  def map_mode_to_trip_type(mode_code=nil)
    {
      "mode_bicycle"      => :bicycle,
      "mode_car"          => :car,
      "mode_paratransit"  => :paratransit,
      "mode_taxi"         => :taxi,
      "mode_walk"         => :walk,
      "mode_ride_hailing" => :uber,
      "mode_transit"      => :transit,
      "mode_bus"          => :transit,
      "mode_rail"         => :transit,
      "mode_gondola"      => :transit,
      "mode_funicular"    => :transit,
      "mode_subway"       => :transit,
      "mode_tram"         => :transit,
      "mode_car_transit"  => :transit,
      "mode_ferry"        => :transit,
      "mode_cable_car"    => :transit,
      nil                 => nil
    }[mode_code]
  end
  
  def import_user(user_attrs)
    
    user_profile_attrs = {
      preferred_modes: user_attrs.delete("preferred_modes").map{|m| map_mode_to_trip_type(m)},
      accommodations: user_attrs.delete("accommodations"),
      characteristics: user_attrs.delete("characteristics")
    }
    email = user_attrs.delete("email")
    preferred_locale = user_attrs.delete("preferred_locale")
          
    user = User.find_or_initialize_by(email: email)
    user.assign_attributes(user_attrs.merge({password: "TEMPpw123", password_confirmation: "TEMPpw123"}))
    user.preferred_locale = Locale.find_by(name: preferred_locale)
    user.save
    user.update_profile(user_profile_attrs)
    
    return user
    
  end
  
end
