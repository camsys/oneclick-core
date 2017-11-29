class ApplicationMailer < ActionMailer::Base
  default from: (ENV['SMTP_FROM_ADDRESS'] || "test.oneclick@gmail.com")
  layout 'mailer'
end
