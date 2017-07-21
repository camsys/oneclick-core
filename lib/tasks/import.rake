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
    
    users_attributes = get_export_data(args, 'users/registered')["users"]
    
    users_attributes.each do |user_attrs|
      user = import_user(user_attrs)
      user.assign_attributes(email: convert_to_guest_email(user.email))
      save_and_log_result(user)
    end
    
  end
  
  desc "Import Geographies"
  task :geographies, [:host, :token, :state] => [:environment, :verify_params] do |t, args|
    
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
      service_attrs["fare_details"] = format_fare_details(service_attrs.delete("fare_details"), service_attrs["fare_structure"].to_sym)
              
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
        svc.remote_logo_url = "#{args['host']}#{logo}"
        save_and_log_result(svc)
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
      :geographies,
      :fare_zones,
      :services
    ]
    
  desc "Cleans up Uniquized Attributes"
  task clean_up: :environment do
    
    # Remove legacy ID from uniquized attributes
    clean_up_uniquized_table(Agency, :name)
    clean_up_uniquized_table(User, :email)
    clean_up_uniquized_table(Service, :name)
    
    
  end

end
