class ApplicationMailer < ActionMailer::Base
  default from: (ENV['SMTP_FROM_ADDRESS'] || "1-Click@camsys.com")
  layout 'mailer'
end
