module Api
  module V2
    class StompingGroundsController < ApiController
      before_action :require_authentication

      #Get all the Stomping Grounds for a user
      def index
        stomping_grounds_hash = @traveler.stomping_grounds.map {|sg| StompingGroundSerializer.new(sg).to_hash}
        render(success_response(stomping_grounds_hash))
      end

      def destroy
        stomping_ground = @traveler.stomping_grounds.find_by(id: params[:id]) 
        if stomping_ground
          stomping_ground.delete
          render(success_response(message: "deleted"))
        else
          render(fail_response(status: 404, message: "Not Found"))
        end
      end
      
    end
  end
end