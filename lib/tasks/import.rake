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
      comments = provider_attrs.delete("comments")
      provider_attrs[:phone] = PhonyRails.normalize_number(provider_attrs.delete("phone"))
      ta = TransportationAgency.find_or_initialize_by(name: provider_attrs["name"])
      ta.assign_attributes(provider_attrs)
      ta.build_comments_from_hash(comments)
      ta.save
      puts "Creating or updating Transportation Agency: ", ta.ai
    end
    
  end
  
  desc "Import Registered Users"
  task :registered_users, [:host, :token] => [:environment, :verify_params] do |t, args|
    
    users_attributes = get_export_data(args, 'users/registered')["users"]
    
    users_attributes.each do |user_attrs|
      user = import_user(user_attrs)
      puts "Creating or Updating User: ", user.ai
    end
    
  end
  
  desc "Import Guest Users"
  task :guest_users, [:host, :token] => [:environment, :verify_params] do |t, args|
    
    users_attributes = get_export_data(args, 'users/registered')["users"]
    
    users_attributes.each do |user_attrs|
      user = import_user(user_attrs)
      user.update_attributes(email: convert_to_guest_email(user.email))
      puts "Creating or Updating User: ", user.ai
    end
    
  end
  
  desc "Cleans up Uniquized Attributes"
  task clean_up: :environment do
    
    # Remove ID from Provider names
    clean_up_uniquized_table(Agency, :name)
    
    # Remove ID from User emails
    clean_up_uniquized_table(User, :email)
    
  end

  desc "Import Everything"
  task :all, [:host, :token] => [
      :purposes, 
      :eligibilities, 
      :accommodations, 
      :providers,
      :registered_users,
      :guest_users
    ]

end
