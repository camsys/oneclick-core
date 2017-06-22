module Api
  module V2
    class StompingGroundsController < ApiController
      before_action :require_authentication, only: [:update]

      #Get all the Stomping Grounds for a user
      def index 
        stomping_grounds_hash = User.find(params[:user_id]).stomping_grounds.map {|sg| StompingGroundSerializer.new(sg).to_hash}
        render(success_response(stomping_grounds_hash))
      end
            
      
    end
  end
end