class DeveloperMailer < ApplicationMailer
  default from: (ENV['SMTP_FROM_ADDRESS'] || "1-Click@camsys.com")

  def ecolane_summary_notification(summary, error_occurred = false)
    @summary = summary.map(&:html_safe)
    environment_name = ENV['MAIL_HOST'] || 'Unknown environment'
    mail(
      to: ENV['JOB_SUMMARY_NOTIFICATION_EMAIL'],
      subject: "Ecolane POI Update Summary (#{environment_name})"
    )
  end
end