class DeveloperMailer < ApplicationMailer
  default from: (ENV['SMTP_FROM_ADDRESS'] || "1-Click@camsys.com")

  def ecolane_summary_notification(summary, error = false)
    @summary = summary
    subject = error ? 'Ecolane POI Update Summary with Errors' : 'Ecolane POI Update Summary'
    mail(to: 'jalen.w.sowell@gmail.com', subject: subject)
  end
end