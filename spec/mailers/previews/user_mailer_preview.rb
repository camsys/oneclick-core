# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview  
  def agency_setup_reminder_preview
    UserMailer.agency_setup_reminder(PartnerAgency.last)
  end

  def user_trip_email
    UserMailer.user_trip_email(User.find(2), Trip.selected.joins('inner join itineraries on trips.selected_itinerary_id = itineraries.id').where("itineraries.trip_type = 'transit'").first)
  end

  def ecolane_trip_email
    UserMailer.ecolane_trip_email(User.first.email, Booking.limit(5))
  end

  def user_trip_reminder
    UserMailer.user_trip_reminder(User.first.email, Trip.selected.transit_trips.first, 7)
  end

end
