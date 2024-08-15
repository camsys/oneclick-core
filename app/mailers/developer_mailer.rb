class DeveloperMailer < ApplicationMailer
  default from: (ENV['SMTP_FROM_ADDRESS'] || "1-Click@camsys.com")

  def ecolane_summary_notification(summary, error_occurred = false)
    # Log the ENV variables and other important information
    Rails.logger.info "JOB_SUMMARY_NOTIFICATION_EMAIL: #{ENV['JOB_SUMMARY_NOTIFICATION_EMAIL']}"
    Rails.logger.info "SMTP_FROM_ADDRESS: #{ENV['SMTP_FROM_ADDRESS'] || '1-Click@camsys.com'}"
    
    # Check if the email address is present
    if ENV['JOB_SUMMARY_NOTIFICATION_EMAIL'].present?
      @summary = summary.map(&:html_safe)
      mail(to: ENV['JOB_SUMMARY_NOTIFICATION_EMAIL'], subject: 'Ecolane POI Update Summary')
      Rails.logger.info "Email sent to: #{ENV['JOB_SUMMARY_NOTIFICATION_EMAIL']}"
    else
      Rails.logger.warn "JOB_SUMMARY_NOTIFICATION_EMAIL is not set, email not sent."
    end
  end
end