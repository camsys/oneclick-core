module Api
  module V1
    class UsersController < ApiController
      before_action :require_authentication, except: [:get_guest_token]

      def profile
        render json: @traveler.profile_hash
      end

      def update
        render json: @traveler.update_profile(params)
      end

      # STUBBED method for communication with UI
      def get_guest_token
        render status: 200, json: {}
      end

    end
  end
end
