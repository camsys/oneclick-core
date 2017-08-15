namespace :import do

  require 'open-uri'
  require 'tasks/helpers/import_task_helpers'
  include ImportTaskHelpers
  
  desc "Check for Host and Token Params"
  task :verify_params, [:host, :token] => [:environment] do |t, args|
    unless args[:host] and args[:token]
      puts 'This command requires a host and token parameter.'
      break
    end
  end
  
  desc "Check for State Param"
  task :verify_state, [:host, :token, :state] => [:environment] do |t, args|
    unless args[:state]
      puts 'This command requires a state parameter (2 letter abbreviation, e.g. "MA").'
      break
    end
  end

  desc "Import Purposes"
  task :purposes, [:host, :token] => [:environment, :verify_params] do |t, args|

    trip_purposes = get_export_data(args, 'trip_purposes')["trip_purposes"]

    trip_purposes.each do |trip_purpose|
      Purpose.where(code: trip_purpose["code"]).first_or_create do |new_purpose|
        puts 'Creating New Trip Purpose'
        puts trip_purpose.ai 
        trip_purpose["phrases"].each do |locale, phrases|
          phrases.each do |key, value|
            new_purpose.set_translation(locale, key, value)  
          end
        end  
      end
    end
  end

  desc "Import Eligibilities"
  task :eligibilities, [:host, :token] => [:environment, :verify_params] do |t, args|

    characteristics = get_export_data(args, 'characteristics')["characteristics"]

    characteristics.each do |characteristic|
      Eligibility.where(code: characteristic["code"]).first_or_create do |new_elig|
        puts 'Creating New Eligibility'
        puts characteristic.ai 
        characteristic["phrases"].each do |locale, phrases|
          phrases.each do |key, value|
            new_elig.set_translation(locale, key, value)  
          end
        end  
      end
    end
  end

  desc "Import Accommodations"
  task :accommodations, [:host, :token] => [:environment, :verify_params] do |t, args|

    accommodations = get_export_data(args, 'accommodations')["accommodations"]

    accommodations.each do |accommodation|
      Accommodation.where(code: accommodation["code"]).first_or_create do |new_acc|
        puts 'Creating New Accommodation'
        puts accommodation.ai 
        accommodation["phrases"].each do |locale, phrases|
          phrases.each do |key, value|
            new_acc.set_translation(locale, key, value)  
          end
        end  
      end
    end
  end
  
  desc "Import Providers"
  task :providers, [:host, :token] => [:environment, :verify_params] do |t, args|

    providers_attributes = get_export_data(args, 'providers')["providers"]
    
    providers_attributes.each do |provider_attrs|
      puts "Attempting to Create or Update Transportation Agency..."
      comments = provider_attrs.delete("comments")
      # provider_attrs[:phone] = PhonyRails.normalize_number(provider_attrs.delete("phone"))
      provider_attrs[:phone] = provider_attrs.delete("phone")
      ta = TransportationAgency.find_or_initialize_by(name: provider_attrs["name"])
      ta.assign_attributes(provider_attrs)
      ta.build_comments_from_hash(comments)
      save_and_log_result(ta)
    end
    
  end
  
  desc "Import Registered Users"
  task :registered_users, [:host, :token] => [:environment, :verify_params] do |t, args|
    
    users_attributes = get_export_data(args, 'users/registered')["users"]
    
    users_attributes.each do |user_attrs|
      import_user(user_attrs)
    end
    
  end
  
  desc "Import Guest Users"
  task :guest_users, [:host, :token] => [:environment, :verify_params] do |t, args|
    
    users_attributes = get_export_data(args, 'users/guests')["users"]
    
    users_attributes.each do |user_attrs|
      user = import_user(user_attrs)
      user.assign_attributes(email: convert_to_guest_email(user.email))
      save_and_log_result(user)
    end
    
  end
  
  desc "Import Admin and Staff Users"
  task :professional_users, [:host, :token] => [:environment, :verify_params] do |t, args|
    
    users_attributes = get_export_data(args, 'users/professionals')["users"]
    
    users_attributes.each do |user_attrs|
      import_user(user_attrs)
    end
    
  end
  
  desc "Import Geographies"
  task :geographies, [:host, :token, :state] => [:environment, :verify_params, :verify_state] do |t, args|
    
    [:cities, :counties, :zipcodes].each do |geo_type|
      geos_attributes = get_export_data(args, "geographies/#{geo_type.to_s}", state: args['state'])["geographies"]
      
      geos_attributes.each do |geo_attrs|
        model_class = geo_type.to_s.classify.constantize
        geo = model_class.find_or_initialize_by(name: geo_attrs["name"])
        geo.assign_attributes(geo_attrs)
        save_and_log_result(geo)
      end
    end
  
  end
  
  desc "Import Fare Zone Geographies"
  task :fare_zones, [:host, :token] => [:environment, :verify_params] do |t, args|
        
    fare_zones_attributes = get_export_data(args, 'geographies/fare_zones')["geographies"]
    
    fare_zones_attributes.each do |fz_attrs|
      fz = CustomGeography.find_or_initialize_by(name: fz_attrs["name"])
      fz.assign_attributes(fz_attrs)
      save_and_log_result(fz)
    end
    
  end

  desc "Import Landmarks"
  task :landmarks, [:host, :token] => [:environment, :verify_params] do |t,args|

    pois = get_export_data(args, "pois")["pois"]
    pois.each do |poi|
      poi.transform_keys!{ |key| key=="lon" ? "lng" : key }
    end

    pois.each do |poi|
      Landmark.where(name: poi['name']).first_or_create do |landmark|
        puts "Creating a new Landmark: #{poi['name']}"
        landmark.update_attributes(poi)
      end
    end

  end
  
  desc "Import Services and Associate w/ Providers"
  task :services, [:host, :token] => [:environment, :verify_params] do |t, args|
    
    services_attributes = get_export_data(args, 'services')["services"]
    
    services_attributes.each do |service_attrs|

      service_attrs["agency_id"] = find_record_by_legacy_id(Agency, service_attrs.delete("provider_id")).try(:id)
      service_attrs["fare_details"] = format_fare_details(service_attrs.delete("fare_details"), service_attrs["fare_structure"].try(:to_sym))
              
      logo = service_attrs.delete("logo")
      comments = service_attrs.delete("comments")
      area_recipes = {
        start_or_end_area: service_attrs.delete("start_or_end_area_recipe"),
        trip_within_area: service_attrs.delete("trip_within_area_recipe")
      }
      schedules = service_attrs.delete("schedules")
      accommodations = service_attrs.delete("accommodations")
      eligibilities = service_attrs.delete("eligibilities")
      purposes = service_attrs.delete("purposes")
      
      svc = Service.find_or_initialize_by(name: service_attrs["name"])
      svc.assign_attributes(service_attrs)
      svc.build_comments_from_hash(comments)
      svc.accommodations = Accommodation.where(code: accommodations)
      svc.eligibilities = Eligibility.where(code: eligibilities)
      svc.purposes = Purpose.where(code: purposes)
      svc.schedules.build(schedules)
      
      svc.build_geographies
      [:start_or_end_area, :trip_within_area].each do |area|
        if svc.send(area)
          svc.send(area).recipe = convert_geo_recipe(area_recipes[area])
          save_and_log_result(svc.send(area))
        end
      end
      
      save_and_log_result(svc)

      # Have to re-initialize service object to get logo to upload properly
      if svc && logo
        svc = Service.find(svc.id)
        svc.reload
        svc.remote_logo_url = ENV["RACK_ENV"] == "development" ? "#{args['host']}#{logo}" : logo
        save_and_log_result(svc)
      end

    end          
    
  end
  
  desc "Import User Roles"
  task :roles, [:host, :token] => [:environment, :verify_params] do |t, args|
  
    roles_attributes = get_export_data(args, 'roles')["roles"]
    
    roles_attributes.each do |role_attrs|      
      user = find_record_by_legacy_id(User, role_attrs["user_id"], column: :email)
      
      resource = nil
      resource = find_record_by_legacy_id(
        translate_resource_type(role_attrs["resource_type"]),
        role_attrs["resource_id"]
      ) if role_attrs["resource_type"] && role_attrs["resource_id"]
      
      role = translate_role_name(role_attrs["name"])

      if user
        puts "Adding role #{role} to user #{user.email}#{" for agency #{resource.name}" if resource}"
        user.add_role(role, resource) 
      end
      
    end
  end
  
  desc "Import Feedbacks"
  task :feedbacks, [:host, :token] => [:environment, :verify_params] do |t, args|
    feedbacks_attributes = get_export_data(args, 'feedbacks')["feedbacks"]
    
    feedbacks_attributes.each do |feedback_attrs|
      
      user = find_record_by_legacy_id(User, feedback_attrs.delete("user_id"), column: :email)

      feedback = Feedback.find_by(created_at: feedback_attrs["created_at"].to_datetime)
      feedback ||= user.present? ? user.feedbacks.build : Feedback.new
      feedback.assign_attributes(feedback_attrs)
      save_and_log_result(feedback)
      
    end
  end
  
  desc "Import Trips"
  task :trips, [:host, :token] => [:environment, :verify_params] do |t, args|
    
    # Get trips in batches
    loop.with_index do |_, i|
      puts "GETTING TRIPS BATCH #{i}..."
      trips_attributes = get_export_data(args, 'trips', batch_size: 50, batch_index: i)["trips"]
      
      break if trips_attributes.empty? || i > 2000
      
      trips_attributes.each do |trip_attrs|
        
        itineraries = trip_attrs.delete("itineraries")
        
        user = find_record_by_legacy_id(User, trip_attrs.delete("user_id"), column: :email)

        trip = Trip.find_by(created_at: trip_attrs["created_at"].to_datetime)
        trip ||= user.present? ? user.trips.build : Trip.new
        trip.assign_attributes(trip_attrs)
        
        itineraries.each do |itin_attrs|
          
          itin_attrs[:trip_type] = map_mode_to_trip_type(itin_attrs.delete("mode"))
          itin_attrs[:service_id] = find_record_by_legacy_id(Service, itin_attrs.delete("service_id"))
          selected = itin_attrs.delete("selected")
          
          itinerary = trip.itineraries.find_by(created_at: itin_attrs["created_at"].to_datetime)
          itinerary ||= trip.itineraries.build
          itinerary.assign_attributes(itin_attrs)
          
          trip.selected_itinerary = itinerary if selected      
        end
        
        save_and_log_result(trip)
                
      end
    end
    
  end
  
  desc "Import Everything"
  task :all, [:host, :token, :state] => [
      :purposes, 
      :eligibilities,
      :accommodations, 
      :providers,
      :registered_users,
      :guest_users,
      :professional_users,
      :geographies,
      :landmarks,
      :fare_zones,
      :services,
      :roles,
      :feedbacks,
      :trips
    ]
    
  desc "Cleans up Uniquized Attributes"
  task clean_up: :environment do
    
    # Remove legacy ID from uniquized attributes
    clean_up_uniquized_table(Agency, :name)
    clean_up_uniquized_table(User, :email)
    clean_up_uniquized_table(Service, :name)
    clean_up_uniquized_table(Waypoint, :name)
    
  end

end
