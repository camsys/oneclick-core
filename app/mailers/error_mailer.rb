class ErrorMailer < ApplicationMailer
  default from: ENV['SMTP_USER_NAME']  # Use the verified email address

  def ecolane_error_notification(errors)
    @errors = errors
    mail(to: 'jalen.w.sowell@gmail.com', subject: 'Ecolane POI Update Error')
  end
end