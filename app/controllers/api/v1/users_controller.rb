module Api
  module V1
    class UsersController < ApiController
      before_action :require_authentication, except: [:get_guest_token]
      # before_action :allow_authentication, only: [:get_guest_token]

      def profile
        render json: authentication_successful? ? @traveler.profile_hash : guest_profile_hash
      end

      def update
        render json: @traveler.update_profile(params)
      end

      # STUBBED method for communication with UI
      def get_guest_token
        render status: 200, json: {}
      end

      private

      def guest_profile_hash
        {
          first_name: "Guest",
          last_name: "User",
          email: "visitor@oneclick.com"
        }
      end

    end
  end
end
