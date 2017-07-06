namespace :scheduled do
  
  desc "test"
  task daily: :environment do
    Config.daily_scheduled_tasks.each do |task|
      Rails.logger.info "Running Scheduled Task: #{task}..."
      Rake::Task["scheduled:#{task}"].invoke
    end
  end
  
  task agency_setup_reminder_emails: :environment do
    PartnerAgency.unpublished
    .where("created_at <= :five_days_ago and created_at > :six_days_ago", 
          five_days_ago: Time.current - 5.days,
          six_days_ago: Time.current - 6.days)
    .each do |agency|
      Rails.logger.info "Sending reminder emails to staff for #{agency.name}..."
      UserMailer.agency_setup_reminder(agency).deliver_now
    end
  end
    
end
