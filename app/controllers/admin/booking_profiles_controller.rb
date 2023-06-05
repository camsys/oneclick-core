class Admin::BookingProfilesController < ApplicationController
  include AdminHelpers
  before_action :ensure_travel_patterns_mode

  def index
    get_admin_pages

    @booking_profiles = if current_user.superuser? || current_user.admin?
                          UserBookingProfile.all
                        elsif current_user.has_role? :oversight_agency
                          current_user.oversight_agency.services.map(&:user_booking_profiles).flatten
                        elsif current_user.has_role? :agency
                          current_user.current_agency.services.map(&:user_booking_profiles).flatten
                        else
                          current_user.user_booking_profiles
                        end
  end

  private

  def ensure_travel_patterns_mode
    unless Config.dashboard_mode.to_sym == :travel_patterns
      redirect_to root_path, alert: 'Access to Booking Profiles is only allowed in travel patterns mode.'
    end
  end

end