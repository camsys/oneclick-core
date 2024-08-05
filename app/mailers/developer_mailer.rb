class DeveloperMailer < ApplicationMailer
  default from: (ENV['SMTP_FROM_ADDRESS'] || "1-Click@camsys.com")

  def ecolane_summary_notification(summary, error_occurred = false)
    return unless ENV['JOB_NOTIFICATION_EMAIL'].present?
    @summary = summary.map(&:html_safe)
    mail(to: ENV['JOB_SUMMARY_NOTIFICATION_EMAIL'], subject: 'Ecolane POI Update Summary')
  end
end