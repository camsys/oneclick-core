# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  def test_email_preview
    UserMailer.test_email("nicolas.o.garcia@gmail.com")
  end
  
  def agency_setup_reminder_preview
    UserMailer.agency_setup_reminder(PartnerAgency.last)
  end
end
