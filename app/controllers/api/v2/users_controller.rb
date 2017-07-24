module Api
  module V2
    class UsersController < ApiController
      before_action :require_authentication

      # Get the user profile 
      def show
        render(success_response(
                @traveler, 
                serializer: UserSerializer))
      end

    end
  end
end