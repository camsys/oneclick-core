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
    @traveler = trip.user
    subject = 'Your Trip Details'
    @itinerary = @trip.selected_itinerary
    unless @itinerary
      return
    end
    if @itinerary.service and @itinerary.service.logo.url
      attachments.inline['service_logo.png'] = open(ActionController::Base.helpers.asset_path(@itinerary.service.logo.thumb.url.to_s), 'rb').read
    end
    map_image = MapService.new(@itinerary).create_static_map
    attachments.inline[@itinerary.id.to_s + ".png"] = open(map_image, 'rb').read
    attach_standard_icons #TODO: Don't attach all icons by default.  Attach them as needed.
    mail(to: addresses, subject: subject)
  end

  # Let admins know when Feedback isn't being acknowledge
  def admin_feedback_reminder(feedbacks)
    subject = 'List of Overdue Feedback'  
    @feedbacks = feedbacks
    mail(to: (User.admins + User.partner_staff).uniq.pluck(:email), subject: subject)
  end

  # Let admins know when Feedback isn't being acknowledge
  def transportation_agency_feedback_reminder(feedback)
    subject = 'Overdue Feedback'   
    @feedback = feedback
    service = @feedback.feedbackable
    if service.agency and service.agency.staff.count > 0
      mail(to: service.agency.staff.pluck(:email), subject: subject)
    end
  end

  # New Feedback Email
  def new_feedback(feedback)
    subject = 'New Feedback'   
    @feedback = feedback

    # If this email is for a service with staff, let them know. Otherwise, let the admin and partners know
    service = (feedback.feedbackable_type == "Service") ? @feedback.feedbackable : nil
    if service and service.agency and service.agency.staff.count > 0
      mail(to: service.agency.staff.pluck(:email), subject: subject)
    else
      mail(to: (User.admins + User.partner_staff).uniq.pluck(:email), subject: subject)
    end
  end
  
  # API V1 password reset email
  def api_v1_reset_password_instructions(user, token)
    @user = user
    @reset_password_path = "#{Config.api_v1_ui_url}?reset_password_token=#{token}"
    mail(to: @user.email, subject: 'Password Reset Instructions')
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
