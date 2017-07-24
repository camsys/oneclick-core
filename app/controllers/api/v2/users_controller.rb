module Api
  module V2
    class UsersController < ApiController
      before_action :require_authentication

      # by agency type (e.g. TransportationAgency, PartnerAgency)
      def show
        render(success_response(
                @traveler, 
                serializer: UserSerializer))
      end

    end
  end
end