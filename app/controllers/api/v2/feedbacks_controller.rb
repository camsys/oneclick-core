module Api
  module V2
    class FeedbacksController < ApiController
      
      before_action :attempt_authentication
      before_action :ensure_traveler
      
      # GET /api/v2/feedbacks
      # Returns a list of the authenticated user's feedbacks, along with their status
      def index
        @feedbacks = @traveler.feedbacks.order(created_at: :desc)
        render(success_response(@feedbacks))
      end
            
      # POST /api/v2/feedbacks
      # Create a feedback for the logged in user
      def create
        if @traveler.present?
          @feedback = @traveler.feedbacks.build(feedback_params) # Builds a feedback belonging to the logged-in user
        else
          @feedback = Feedback.new(feedback_params)
        end
        
        if @feedback.save # Render a success response only if feedback saves successfully
          UserMailer.new_feedback(@feedback).deliver_now # Alert proper people that new feedback was submitted.
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
