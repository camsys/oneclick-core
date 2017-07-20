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

  # Returns the id from the end of a uniquized string
  def id_from_uniquized_attribute(attr_value)
    /\A.*\${2}(.*)\Z/.match(attr_value)[1]
  end
  
  # Pulls the id off the email and appends it to a new guest email
  def convert_to_guest_email(email)
    id = id_from_uniquized_attribute(email)
    GuestUserHelper.new.random_email + "$$#{id}"
  end
  
  # Pulls the id off of a uniquized attribute
  def ununiquize_attribute(attr_value)
    attr_value.gsub(/\${2}.*/, '')
  end
  
  # Cleans Up Uniquized Table, given the table name and the uniquized attribute
  def clean_up_uniquized_table(table, attr)
    puts "Cleaning up #{table.name} Table..."
    table.where("#{attr} LIKE '%$$%'").each do |r| 
      puts "Cleaning up #{attr} of #{table.name.underscore} #{r.id}"
      unless r.update_attributes(attr => ununiquize_attribute(r.send(attr)))
        puts "FAILED: #{r.errors.full_messages}"
      end
    end
  end
  
  def find_record_by_legacy_id(model, legacy_id, opts={})
    column = opts[:column] || :name
    model.where("#{column} LIKE '%$$#{legacy_id}'").first
  end
  
  def format_fare_details(fare_details, fare_structure)
    case fare_structure
    when :flat
    when :mileage
      fare_details["trip_type"] = fare_details["trip_type"].to_sym
    when :zone
    when :taxi_fare_finder
    else
    end
    
    return fare_details.with_indifferent_access

  end
  
end
