module Api
  module V1
    class FeedbacksController < ApiController
      
      before_action :require_authentication, only: [:create]
      
      # POST /api/v1/feedbacks
      # Create a feedback for the logged in user
      def create
        feedback = @traveler.feedbacks.build(feedback_params)
        if feedback.save
          render(success_response(message: "Feedback successfully created"))
        else
          render(fail_response(errors: feedback.errors.to_h))
        end
      end
      
      protected
      
      def feedback_params
        params.require(:feedback).permit(
          :feedbackable_id,
          :feedbackable_type,
          :rating,
          :comment
        )
      end
      
      
    end
  end
end
