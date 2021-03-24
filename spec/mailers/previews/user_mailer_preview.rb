# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview  
  def agency_setup_reminder_preview
    UserMailer.agency_setup_reminder(PartnerAgency.last)
  end

  def user_trip_email
    UserMailer.user_trip_email(User.find(2), Trip.find(70))
  end

  def ecolane_trip_email
    UserMailer.ecolane_trip_email('wjiang@camsys.com', Booking.limit(5))
  end

end
