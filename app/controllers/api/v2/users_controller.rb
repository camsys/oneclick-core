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

      # Update's the user's profile
      def update
        if @traveler.update_profile(params)
          render(success_response(@traveler, serializer: UserSerializer))
        else
          render(fail_response(status: 500, message: "Unable to update."))
        end
      end

    end
  end
end