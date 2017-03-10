module Api
  module V1
    class UsersController < ApiController

      def profile
        render json: @traveler.profile_hash
      end
    
    end
  end
end