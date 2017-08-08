class UserMailer < ApplicationMailer

  helper :email
  
  def agency_setup_reminder(agency)
    @agency = agency
    email_list = (agency.staff.pluck(:email) + [@agency.email] + User.admins.pluck(:email)).compact
    
    mail(to: email_list, subject: "Reminder to Set Up #{@agency.name}")
  end

  # Here to Support API/V1 
  def user_trip_email(addresses, trip)
    @trip = trip
    subject = 'Your Trip Details'
    @itinerary = @trip.selected_itinerary
    unless @itinerary
      return
    end
    #@itinerary.map_image = create_static_map(@itinerary)
    #attachments.inline[@itinerary.id.to_s + ".png"] = open(@itinerary.map_image, 'rb').read
    #["start.png", "stop.png"].each do |icon|
    #  attach_image(icon)
    #end
    mail(to: addresses, subject: subject)
  end
  
end
