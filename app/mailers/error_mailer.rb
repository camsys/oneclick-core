class ErrorMailer < ApplicationMailer
  default from: (ENV['SMTP_FROM_ADDRESS'] || "1-Click@camsys.com")

  def ecolane_error_notification(errors)
    @errors = errors.map(&:html_safe)
    mail(to: 'jalen.w.sowell@gmail.com', subject: 'Ecolane POI Update Error')
  end
end