# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview  
  def agency_setup_reminder_preview
    UserMailer.agency_setup_reminder(PartnerAgency.last)
  end
end
