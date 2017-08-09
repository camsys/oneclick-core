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
    map_image = MapService.new(@itinerary).create_static_map
    attachments.inline[@itinerary.id.to_s + ".png"] = open(map_image, 'rb').read
    attach_standard_icons #TODO: Don't attach all icons by default.  Attach them as needed.
    mail(to: addresses, subject: subject)
  end

  private

  # Attaches an asset to the email based on its filename (including extension)
  def attach_standard_icons
    ["start.png", "stop.png", "auto.png", "bicycle.png", "bus.png", "rail.png", "subway.png", "taxi.png", "walk.png"].each do |icon|
      url = "#{Rails.root}/app/assets/images/email/#{icon}"
      attachments.inline[icon] = File.read(url)
    end
  end
  
end
