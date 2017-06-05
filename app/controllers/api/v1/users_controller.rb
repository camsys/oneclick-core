module Api
  module V1
    class UsersController < ApiController
      before_action :require_authentication, only: [:update]
      before_action :current_or_guest_user, only: [:get_guest_token] #If @traveler is not set, then create a guest user account

      # Sends back a profile hash via the API::V1::UserSerializer
      def profile
        render json: @traveler
      end

      # Update's the logged-in user's profile
      def update
        render json: @traveler.update_profile(params)
      end

      # Used by API/v1 to create guest users on command
      def get_guest_token
        render status: 200, json: {email: @traveler.email, authentication_token: @traveler.authentication_token}
      end

    end
  end
end
