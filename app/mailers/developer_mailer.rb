class DeveloperMailer < ApplicationMailer
  default from: (ENV['SMTP_FROM_ADDRESS'] || "1-Click@camsys.com")

  def ecolane_summary_notification(summary, error_occurred = false)
    @summary = summary.map(&:html_safe)
    mail(to: 'jalen.w.sowell@gmail.com', subject: 'Ecolane POI Update Summary')
  end
end