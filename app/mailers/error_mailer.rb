class ErrorMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def ecolane_error_notification(errors)
    @errors = errors
    mail(to: ENV['ECOLANE_ERROR_NOTIFICATION_EMAILS'].split(','), subject: 'Ecolane POI Update Error')
  end
end