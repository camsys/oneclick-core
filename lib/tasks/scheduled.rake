namespace :scheduled do
  
  desc "test"
  task daily: :environment do
    Config.daily_scheduled_tasks.each do |task|
      Rails.logger.info "Running Scheduled Task: #{task}..."
      Rake::Task["scheduled:#{task}"].invoke
    end
  end
  
  desc "Send Agency Staff Reminders to Set up their Agency Profile"
  task agency_setup_reminder_emails: :environment do
    # Every five days for a month, if a new agency hasn't been published, send a reminder to all its staff.
    (1..5).each do |i|
      PartnerAgency.unpublished
      .where("created_at <= ? and created_at > ?", 
            Time.current - (i*5).days,
            Time.current - (i*5+1).days)
      .each do |agency|
        Rails.logger.info "Sending reminder emails to staff for #{agency.name}..."
        UserMailer.agency_setup_reminder(agency).deliver_now
      end
    end
  end
  
  # For each service with a RidePilot booking profile, make a get_purposes
  # call and update the ridepilot_purposes config hash map.
  desc "Pull Purposes Hash From RidePilot"
  task get_ridepilot_purposes: :environment do
    
    puts "Updating RidePilot Purposes Map..."

    purposes_config = Config.find_or_initialize_by(key: :ridepilot_purposes)
    purposes_config.value ||= {}
    
    Service.where(booking_api: :ridepilot)
      .each do |svc|
        puts "Getting purposes for Service: #{svc.to_s}"
        rpa = RidePilotAmbassador.new(svc)
        new_purposes = rpa.trip_purposes.try(:[], "trip_purposes") || []
        new_purposes.each do |purp|
          key = purp["name"].to_s.parameterize.underscore
          puts "Updating Purpose #{key} with code: #{purp["code"]}"
          purposes_config.value[key] = purp["code"]
        end
      end
    
    if purposes_config.save
      puts "RidePilot Purposes Updated Successfully"
    else
      puts "Problem updating RidePilot Purposes: " + purposes_config.errors.full_messages.to_sentence
    end
    
  end
    
end
