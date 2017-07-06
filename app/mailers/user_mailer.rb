class UserMailer < ApplicationMailer
  
  def test_email(addr)
    mail(to: addr, subject: "TEST EMAIL")
  end
  
  def agency_setup_reminder(agency)
    @agency = agency
    email_list = (agency.staff.pluck(:email) + [@agency.email] + User.admins.pluck(:email)).compact
    
    mail(to: email_list, subject: "Reminder to Set Up #{@agency.name}")
  end
  
end
