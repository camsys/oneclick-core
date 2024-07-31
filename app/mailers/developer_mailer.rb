class DeveloperMailer < ApplicationMailer
  default from: (ENV['SMTP_FROM_ADDRESS'] || "1-Click@camsys.com")

  def ecolane_summary_notification(summary, error_occurred = false)
    @summary = summary
    subject = error_occurred ? 'Ecolane POI Update Summary (Errors Occurred)' : 'Ecolane POI Update Summary'
    mail(to: 'jalen.w.sowell@gmail.com', subject: subject)
  end
end