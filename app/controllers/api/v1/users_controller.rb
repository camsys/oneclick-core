module Api
  module V1
    class UsersController < ApiController
      before_action :require_authentication, only: [:update]

      # Sends back a profile hash via the API::V1::UserSerializer
      def profile
        render json: authentication_successful? ? @traveler : guest_profile
      end

      # Update's the logged-in user's profile
      def update
        render json: @traveler.update_profile(params)
      end

      # STUBBED method for communication with UI
      def get_guest_token
        render status: 200, json: {}
      end

      private

      # Creates a new user with default values, but does not persist to the database
      def guest_profile
        User.new(
          first_name: "Guest",
          last_name: "User",
          email: "visitor@oneclick.com"
        )
      end

    end
  end
end
