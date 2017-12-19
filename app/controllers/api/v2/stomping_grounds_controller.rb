module Api
  module V2
    class StompingGroundsController < ApiController

      # Check for user auth info, but don't require it
      before_action :attempt_authentication

      #Get all the Stomping Grounds for a user
      def index
        @stomping_grounds = @traveler.present? ? @traveler.stomping_grounds : []
        
        render(success_response(@stomping_grounds,
                root: "stomping_grounds"))
      end

      def destroy
        @stomping_ground = @traveler.present? ? @traveler.stomping_grounds.find_by(id: params[:id]) : nil
        if @stomping_ground
          @stomping_ground.delete
          render(success_response(message: "Deleted"))
        else
          render(fail_response(status: 404, message: "Not found"))
        end
      end

      def create
        @stomping_ground = StompingGround.initialize_from_google_place_attributes(params[:stomping_ground])
        @stomping_ground.user = @traveler if @traveler.present?
        if @stomping_ground.save
          render(success_response(message: "Created a new Stomping Ground with id: #{@stomping_ground.id}"))
        else
          render(fail_response(message: "Unable to create Stomping Ground"))
        end
      end

      def update
        @stomping_ground = @traveler.present? ? @traveler.stomping_grounds.find_by(id: params[:id]) : nil
        if @stomping_ground
          @stomping_ground.update_from_google_place_attributes(params[:stomping_ground])
          render(success_response(message: "Updated"))
        else
          render(fail_response(status: 404, message: "Not found"))
        end

      end
      
    end
  end
end
