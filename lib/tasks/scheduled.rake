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
    5.times do |i|
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
    
end
