class Admin::BookingProfilesController < ApplicationController
  include AdminHelpers
  before_action :get_admin_pages
  before_action :ensure_travel_patterns_mode

  def index
    if current_user.superuser?
      @booking_profiles = UserBookingProfile.all
    else
      ag_ids = @agency_map.map { |name, id| id } # Get agency ids from the agency map
      selected_agency_id = params[:agency][:id] if params[:agency].present?
      
      if selected_agency_id.present? && ag_ids.include?(selected_agency_id.to_i)
        @booking_profiles = UserBookingProfile.includes(service: :agency)
                                              .where(services: { agency_id: selected_agency_id.to_i })
      else
        @booking_profiles = UserBookingProfile.includes(service: :agency)
                                              .where(services: { agency_id: ag_ids })
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