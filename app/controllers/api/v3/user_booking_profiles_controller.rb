# module Api
#   module V3
#     class UserBookingProfilesController < ApiController
class Api::V3::UserBookingProfilesController < Api::ApiController
  before_action :require_authentication

  def index
    render status: 200, json: @traveler.user_booking_profiles.with_valid_service.as_json
  end

  def create
    
  end

  def select
    profile_id = params[:user_booking_profile][:id]
    profile = @traveler.user_booking_profiles.find_by!(profile_id)
    
    # if @traveler.update(active_booking_profile: profile)
    # else
    # end
  end

  def destroy
    profile_id = params[:user_booking_profile][:id]
    profile = @traveler.user_booking_profiles.find_by!(profile_id)

    if profile.destroy
      render status: 200, json: profile.as_json
    else
      render status: 500, json: {error: profile.errors.full_messages}
    end
  end
end
