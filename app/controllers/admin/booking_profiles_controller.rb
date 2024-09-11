class Admin::BookingProfilesController < ApplicationController
  include AdminHelpers
  before_action :get_admin_pages
  before_action :ensure_travel_patterns_mode

  def index
    selected_agency_id = session[:selected_agency_id] || current_user.current_agency&.id

    if current_user.superuser? || selected_agency_id.blank?
      @booking_profiles = UserBookingProfile.all
    else
      # Find selected agency
      selected_agency = Agency.find_by(id: selected_agency_id)

      if selected_agency.is_a?(OversightAgency)
        # If the selected agency is an oversight agency, get all booking profiles for its associated agencies
        agency_ids = AgencyOversightAgency.where(oversight_agency_id: selected_agency.id).pluck(:transportation_agency_id)
        @booking_profiles = UserBookingProfile.includes(service: :agency).where(services: { agency_id: agency_ids })
      else
        # Otherwise, get the booking profiles for the selected agency's services
        @booking_profiles = UserBookingProfile.includes(service: :agency).where(services: { agency_id: selected_agency.id })
      end
    end
  end

  private

  def ensure_travel_patterns_mode
    unless Config.dashboard_mode.to_sym == :travel_patterns
      redirect_to root_path, alert: 'Access to Booking Profiles is only allowed in travel patterns mode.'
    end
  end
end
