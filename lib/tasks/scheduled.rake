namespace :scheduled do
  
  desc "Running Daily Tasks"
  task daily: :environment do
    Config.daily_scheduled_tasks.each do |task|
      Rails.logger.info "Running Scheduled Task: #{task}..."
      Rake::Task["scheduled:#{task}"].invoke
    end
  end

  desc "TEMPORARY - Sync all Ecolane Users back for 14 days - excludes archived trips"
  task sync_all_ecolane_users_2_weeks: :environment do
    Rake::Task["scheduled:sync_all_ecolane_users_X_days"].invoke(14)
  end

  desc "TEMPORARY - Add notification preferences"
  task add_notification_preferences: :environment do
    hash = {
      notification_preferences: {
        fixed_route: [7,3,1]
      }
    }
    # Fetch all registered travelers and build them a default booking profile
    User.registered_travelers.each do |user|
      unless !user.user_booking_profiles.where(service_id: nil).empty? && !user.registered_traveler?
        user.user_booking_profiles.create({details: hash})
      end
    end
  end

  desc "Sync all Ecolane Users back for 3 days"
  task sync_all_ecolane_users_3_days: :environment do
    Rake::Task["scheduled:sync_all_ecolane_users_X_days"].invoke(3,true)
  end

  desc "sync x days for all users"
  # in zsh call like this:
  # rake 'scheduled:sync_all_ecolane_users_X_days[1234]'
  # args:  :days (required)  :verbose optional defaults to false
  task :sync_all_ecolane_users_X_days, [:days, :verbose] => [:environment] do |t, args|
    include ActionView::Helpers::NumberHelper
    include ActiveModel::Type  # for Boolean cast
    ndays = args[:days].to_i
    ndays = [ndays, 1].max

    verbose = Boolean.new.cast(args[:verbose]) || false
    logger = Rails.logger
    fails = 0
    errors = []
    task_start = Time.now
    count = User.count
    users_processed = 0
    puts "Starting #{ndays} day #{verbose ? "": "non-"}verbose Sync for #{count} users at #{task_start}" 
    User.all.order(:id).each do |u|
      user_start = Time.now
      begin 
        u.sync(ndays)
        users_processed += 1
        if verbose
          puts "Synced user #{u.id} in #{number_with_precision(Time.now - user_start, precision:2)} seconds"
        else
          if users_processed % 50 == 0 then puts "#{users_processed} users synced..." end
        end
      rescue => e
        logger.error "Rake task: Sync fail for user #{u.id}"
        logger.error e.message
        errors << "Sync Error detail for user_id #{u.id}: #{e.message}"
        fails += 1
        puts  "Sync fail for user_id #{u.id}"
      end
    end
    task_end = Time.now
    puts "#{count} users updated with #{fails} failures at #{task_end}"
    puts "Task duration #{number_with_precision((task_end - task_start)/60.0, precision:1)} minutes"
    errors.each do |e|
      unless e.nil?
        index = e.index("rabbit-test") || e.length - 1
        puts e[0..index]
      end
    end
  end


  desc "DEBUGGING sync 3 days for single user"
  # in zsh call like this:
  # rake 'scheduled:sync_single_ecolane_user[1234]''
  task :sync_single_ecolane_user, [:id] => [:environment] do |t, args|
    include ActionView::Helpers::NumberHelper
    logger = Rails.logger
    fails = 0
    errors = []
    puts "Starting Sync for single user with id #{args[:id]} at #{Time.current}"
    task_start = Time.now
    User.where(id: args[:id]).each do |u|
      puts "Syncing user_id #{u.id} start: #{task_start}"
      begin
        u.sync(3)
        puts "Synced user #{u.id} in #{number_with_precision(Time.now - task_start, precision:2)} seconds"
      rescue => e
        logger.error "Rake task sync_single_ecolane_user: Sync fail for user #{u.id}"
        logger.error e.message
        errors << "Sync Error detail for user_id #{u.id}: #{e.message}"
        fails += 1
        puts  "Sync fail for user_id #{u.id}"
      end
    end
    task_end = Time.now
    puts "User updated with #{fails} failures : finished at #{Time.now}"
    puts "Task duration #{number_with_precision((task_end - task_start)/60.0, precision:1)} minutes"
    errors.each do |e|
      #specific parsing for errors due to internal user
      unless e.nil?
        index = e.index("rabbit-test") || e.length - 1
        puts e[0..index]
      end
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
    Agency.published.where('updated_at < ?', DateTime.current - 6.months).each do |agency|
      Rails.logger.info "Sending update reminder emails to staff for #{agency.name}..."
      UserMailer.agency_update_reminder(agency).deliver_now
      
      # reset the agency's updated_at time to now, so that this message doesn't send again for 6 months
      agency.update_attributes(updated_at: DateTime.current)
    end
  end

  desc "Periodically Send Service Staff Reminders to Update their Services"
  task service_update_reminder_emails: :environment do
    # send an update email to agency staff if the agency hasn't been updated in 6 months
    Service.published.where('updated_at < ?', DateTime.current - 6.months).each do |service|
      Rails.logger.info "Sending update reminder emails to staff for #{service.name}..."
      UserMailer.service_update_reminder(service).deliver_now
      
      # reset the agency's updated_at time to now, so that this message doesn't send again for 6 months
      service.update_attributes(updated_at: DateTime.current)
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

  desc "Purge Unused Guest Accounts"
  task purge_unused_guests: :environment do
    User.guests.where('created_at < ?', Time.now-10.days).each do |user|
      user.destroy if user.trips.count == 0
    end
  end

 desc "Send Fixed Trip Reminders"
  task send_fixed_trip_reminders: :environment do
    count = 0
    console_str = Config::DEFAULT_NOTIFICATION_PREFS.join(", ")
    puts "Emailing notifications for trips: #{console_str} days away"

    # For each default notification day, look for trips within that range
    # NOTE: below algorithm assumes that the order of the fixed route trip notifications
    # ...matches the order that the reminders in Config::DEFAULT_NOTIFICATION_PREFS are in
    Config::DEFAULT_NOTIFICATION_PREFS.each.with_index do |default_day, index|

      # Select all transit trips that are in the next n days
      # so i.e transit trips that are in the next 7 days, 3 days, and 1 days
      trips = Trip.transit_trips.in_next_n_days(default_day).distinct
      trips.each do |trip|
        # get user email
        email = trip.user.to_s

        details = trip.details
        fixed_route = details[:notification_preferences][:fixed_route]
        reminder = fixed_route[index]
        # If the trip reminder is enabled and
        # ...the trip reminder day is the same as the Config Notification Day, send an email
        if reminder[:enabled] == true && reminder[:day] == default_day
          UserMailer.user_trip_reminder(email,trip,default_day)

          # toggle enable state of the
          fixed_route[index][:enabled] = false

          trip.update(details: details)
          count += 1
        else
          # continue on without doing anything
          next
        end
      end
    end
    puts "Trip reminder task completed, #{count} emails sent"
  end


  desc "Incrementally delete orphaned Waypoints"
  task clean_waypoints: :environment do
    origin_id_set = Trip.pluck(:origin_id).to_set
    dest_id_set = Trip.pluck(:destination_id).to_set

    puts "Starting count: #{Waypoint.count}"
    # Limit processing time
    start = Time.now
    limit = 2.hours

    batch_size = 1000
    last_id = 0
    
    count = 0
    deleted = 0
    
    Waypoint.uncached do
      while (Time.now - start < limit)
        ids = Waypoint.order(:id).where('id > ?', last_id).limit(batch_size).pluck(:id)
        break if ids.count < 1
        ids.each do |id|
          count += 1
          unless ((origin_id_set.include? id) || (dest_id_set.include? id))
            Waypoint.delete(id)
            deleted += 1
          end
        end
        last_id = ids.last
        print '.'
      end
    end
    puts
    puts "Processed: #{count}, deleted: #{deleted}, elapsed: #{Time.at(Time.now - start).utc.strftime('%H:%M:%S')}"
    puts "Ending count: #{Waypoint.count}"
  end
      
end
