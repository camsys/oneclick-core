module Api
  module V2
    class AlertsController < ApiController

      # GET /api/v2/alerts
      def index

        # If traveler is authenticated serve back their user alerts
        if authentication_successful?
          @traveler.update_alerts
          render(success_response(
                @traveler.user_alerts.is_published.is_current.is_not_acknowledged,
                root: "user_alerts"))
        else # Otherwise, build temporary user alerts for each global alert and serve those
          global_alerts = Alert.current.is_published.for_everyone
                               .map { |alert| alert.user_alerts.build }
          render(success_response(global_alerts, {root: "user_alerts"}))
        end
      end

      def update
        user_alert= @traveler.user_alerts.find_by(id: params[:id]) 
        if user_alert
          user_alert.update_attributes(user_alert_params)
          render(success_response(message: "Updated"))
        else
          render(fail_response(status: 404, message: "Not found"))
        end
      end
      
      protected
      
      def user_alert_params
        params.require(:user_alert).permit(
          :acknowledged
        )
      end
      
      
    end
  end
end
