class UserMailer < ApplicationMailer

  include TranslationHelper # translate(key) in @locale using SimpleTranslationEngine
  helper :email

  def agency_setup_reminder(agency)
    @agency = agency
    email_list = (agency.staff.pluck(:email) + [@agency.email] + User.admins.pluck(:email)).compact
    
    mail(to: email_list, subject: "Reminder to Set Up #{@agency.name}")
  end
  
  def agency_update_reminder(agency)
    @agency = agency
    email_list = (agency.staff.pluck(:email) + [@agency.email] + User.admins.pluck(:email)).compact
    
    mail(to: email_list, subject: "Reminder to Update #{@agency.name}")
  end

  def service_update_reminder(service)
    @service = service
    if @service.agency 
      email_list = (@service.agency.staff.pluck(:email) + [@service.agency.email] + User.admins.pluck(:email)).compact
    else 
      email_list = User.admins.pluck(:email).uniq.compact
    end
     

    mail(to: email_list, subject: "Reminder to Update #{@service.name}")
  end
  
  def user_profile_update_reminder(user)
    @user = user
    @locale = @user.locale.try(:name)
    @subject = translate("api_v2.emails.user_profile_update_reminder.subject")
    @unsubscribe_path = "#{Config.ui_url}/unsubscribe/#{@user.email}"
    mail(to: user.email, subject: @subject)
  end

  def new_traveler(user)
    @user = user
    @subject = "TRANSLATED WELCOME MESSAGE"
    mail(to: user.email, subject: @subject)
  end

  # Here to Support API/V1 
  def user_trip_email(addresses, trip, itinerary=nil)
    @trip = trip
    @traveler = trip.user
    @locale = @traveler.locale.try(:name)
    subject = [application_title, "Trip Details sent to you by traveler's request"].compact.join(" ")
    @itinerary = itinerary || @trip.selected_itinerary
    unless @itinerary
      return
    end

    attach_service_logo
    attach_map_image
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
    @locale = @user.locale.try(:name)
    @reset_password_path = "#{Config.ui_url}?reset_password_token=#{token}"
    mail(to: @user.email, subject: 'Password Reset Instructions')
  end
  
  # API V2 password reset email
  # Sends an email to the user with the given new password
  def api_v2_reset_password_instructions(user, new_password)
    @user = user
    @locale = @user.locale.try(:name)
    @new_password = new_password
    mail(to: @user.email, subject: 'Password Reset Instructions')
  end

  def ecolane_trip_email(addresses, bookings)
    @decorated_bookings = bookings   # form [[booking, trip_hash],...]
    subject = [application_title, "Trip Details sent to you by traveler's request"].compact.join(" ")
    mail(to: addresses, subject: subject)
  end

  def user_trip_reminder(addresses,trip,days_away)
    @days_away = days_away
    @trip = trip
    @traveler = @trip.user
    @locale = @traveler.locale.try(:name)
    subject = [application_title, "Trip Reminder!"].compact.join(" ")
    @itinerary = @trip.selected_itinerary
    unless @itinerary
      return
    end
    
    attach_service_logo
    attach_map_image
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

  def attach_service_logo
    if @itinerary.service and @itinerary.service.logo.url.present?
      begin
        attachments.inline['service_logo.png'] = open(ActionController::Base.helpers.asset_path(@itinerary.service.logo.thumb.url.to_s), 'rb').read
      rescue Errno::ENOENT
        Rails.logger.error "Failure to attach logo to email: '#{@itinerary.service.logo.thumb.url.to_s}' is not a valid path for a logo."
      rescue StandardError => e
        Rails.logger.error e
      end
    end
  end

  def attach_map_image
    if ENV['GOOGLE_API_KEY'].present?
      begin
        map_image = MapService.new(@itinerary).create_static_map
        attachments.inline[@itinerary.id.to_s + ".png"] = open(map_image, 'rb').read
      rescue StandardError => e
        Rails.logger.error e
      end
    end
  end

  def application_title
    Config.application_title.present? ? Config.application_title : nil
  end
  
end
