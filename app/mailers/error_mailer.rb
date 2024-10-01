class ErrorMailer < ApplicationMailer
  default from: (ENV['SMTP_FROM_ADDRESS'] || "1-Click@camsys.com")

  def ecolane_error_notification(errors)
    return unless ENV['JOB_ERROR_NOTIFICATION_EMAIL'].present?

    @errors = errors.map(&:html_safe)
    environment_name = ENV['AWS_BUCKET'] || 'Unknown environment'
    mail(
      to: ENV['JOB_ERROR_NOTIFICATION_EMAIL'],
      subject: "Ecolane POI Update Error (#{environment_name})"
    )
  end
end