class ErrorMailer < ApplicationMailer
  default from: (ENV['SMTP_FROM_ADDRESS'] || "1-Click@camsys.com")

  def ecolane_error_notification(errors)
    @errors = errors
    mail(to: ENV['ERROR_NOTIFICATION_EMAIL'], subject: 'Ecolane POI Update Error')
  end
end