module Api
  module V2
    class FeedbacksController < ApiController
            
      # POST /api/v1/feedbacks
      # Create a feedback for the logged in user
      def create
        if authentication_successful?
          @feedback = @traveler.feedbacks.build(feedback_params) # Builds a feedback belonging to the logged-in user
        else
          @feedback = Feedback.new(feedback_params)
        end
        
        if @feedback.save # Render a success response only if feedback saves successfully
          render(success_response(message: "Feedback successfully created"))
        else
          render(fail_response(errors: @feedback.errors.to_h))
        end
      end
      
      protected
      
      def feedback_params
        params.require(:feedback).permit(
          :feedbackable_id,
          :feedbackable_type,
          :rating,
          :review,
          :email,
          :phone
        )
      end
      
      
    end
  end
end
