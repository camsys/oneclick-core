namespace :import do

  require 'open-uri'

  desc "Import Purposes"
  task :purposes, [:host, :token] => [:environment] do |t, args|

    unless args[:host] and args[:token]
      puts 'This command requires a host and token parameter.'
      break
    end

    url = "#{args['host']}/export/trip_purposes?token=#{args['token']}"
    puts "Calling: #{url}"
    response = JSON.parse(open(url).read)
    response["trip_purposes"].each do |trip_purpose|
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
  task :eligibilities, [:host, :token] => [:environment] do |t, args|

    unless args[:host] and args[:token]
      puts 'This command requires a host and token parameter.'
      break
    end

    url = "#{args['host']}/export/characteristics?token=#{args['token']}"
    puts "Calling: #{url}"
    response = JSON.parse(open(url).read)
    response["characteristics"].each do |characteristic|
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
  task :accommodations, [:host, :token] => [:environment] do |t, args|

    unless args[:host] and args[:token]
      puts 'This command requires a host and token parameter.'
      break
    end

    url = "#{args['host']}/export/accommodations?token=#{args['token']}"
    puts "Calling: #{url}"
    response = JSON.parse(open(url).read)
    response["accommodations"].each do |accommodation|
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

  desc "Import Everything"
  task :all, [:host, :token] => [:environment] do |t, args| 
    Rake::Task["import:purposes"].invoke(args[:host], args[:token])
    Rake::Task["import:eligibilities"].invoke(args[:host], args[:token])
    Rake::Task["import:accommodations"].invoke(args[:host], args[:token])
  end

end