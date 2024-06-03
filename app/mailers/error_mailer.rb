class ErrorMailer < ApplicationMailer
  default from: 'noreply@1click.com'

  def ecolane_error_notification(errors)
    @errors = errors
    mail(to: 'jalen.w.sowell@gmail.com', subject: 'Ecolane POI Update Error')
  end
end