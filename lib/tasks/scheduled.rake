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
        Rails.logger.info "Sending setup reminder emails to staff for #{agency.name}..."
        UserMailer.agency_setup_reminder(agency).deliver_now
      end
    end
  end
  
  desc "Periodically Send Agency Staff Reminders to Update their Agencies"
  task agency_update_reminder_emails: :environment do
    # send an update email to agency staff if the agency hasn't been updated in 6 months
    Agency.where('updated_at < ?', DateTime.current - 6.months).each do |agency|
      Rails.logger.info "Sending update reminder emails to staff for #{agency.name}..."
      UserMailer.agency_update_reminder(agency).deliver_now
      
      # reset the agency's updated_at time to now, so that this message doesn't send again for 6 months
      agency.update_attributes(updated_at: DateTime.current)
    end
  end
  
  desc "Periodically Send Registered Travelers Reminders to Update their Profile"
  task user_profile_update_emails: :environment do
    # To all users on the email list that haven't been updated in over a year, send a reminder email
    User.registered_travelers
    .subscribed_to_emails
    .where('updated_at < ?', DateTime.current - 1.year)
    .each do |user|
      Rails.logger.info "Sending profile update reminder emails to user #{user.email}..."
      UserMailer.user_profile_update_reminder(user).deliver_now
      
      # reset the user's updated_at time to now, so this message doesn't send again for 12 months
      user.update_attributes(updated_at: DateTime.current)
    end
  end
  
  # For each service with a RidePilot booking profile, make a get_purposes
  # call and update the ride_pilot_purposes config hash map.
  desc "Pull Purposes Hash From RidePilot"
  task get_ride_pilot_purposes: :environment do
    
    puts "Updating RidePilot Purposes Map..."

    purposes_config = Config.find_or_initialize_by(key: :ride_pilot_purposes)
    purposes_config.value ||= {}
    
    Service.where(booking_api: :ride_pilot)
      .each do |svc|
        puts "Getting purposes for Service: #{svc.to_s}"
        rpa = RidePilotAmbassador.new({service: svc})
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

  # Email Agencies and the Admin when Feedback is not being dealt with.
  desc "Send Feedback Follow Up Reminders"
  task feedback_reminders: :environment do
    
    # Send Admins and Partners a Summary of all Outstanding Feedback
    all_feedback = Feedback.needs_reminding
    if all_feedback.count > 0
      UserMailer.admin_feedback_reminder(all_feedback).deliver_now
    end

    # Send Transportation Agencies Feedback
    Feedback.service.needs_reminding.each do |feedback|
      if feedback.feedbackable_type == "Service"
        UserMailer.transportation_agency_feedback_reminder(feedback).deliver_now
      end 
    end

  end
    
end
