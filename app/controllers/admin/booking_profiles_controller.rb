class Admin::BookingProfilesController < ApplicationController
  include AdminHelpers
  before_action :get_admin_pages
  before_action :ensure_travel_patterns_mode


  def index
    if current_user.superuser?
      @booking_profiles = UserBookingProfile.all
    elsif current_user.oversight_admin? || current_user.oversight_staff? || current_user.transportation_admin? || current_user.transportation_staff? || current_user.staff? || current_user.partner_staff? || current_user.partner_admin?
      ag_ids = @agency_map.map {|name, id| id} # Get agency ids from the agency map
      @booking_profiles = UserBookingProfile.includes(service: :agency).where(services: {agency_id: ag_ids})
    else
      selected_agency_id = session[:selected_agency_id] || current_user.current_agency&.id
      ag_ids = [selected_agency_id].compact
      @booking_profiles = UserBookingProfile.includes(service: :agency).where(services: { agency_id: ag_ids })
    end
  end

  private

  def ensure_travel_patterns_mode
    unless Config.dashboard_mode.to_sym == :travel_patterns
      redirect_to root_path, alert: 'Access to Booking Profiles is only allowed in travel patterns mode.'
    end
  end
end