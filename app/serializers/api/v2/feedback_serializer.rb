module Api
  module V2
    class FeedbackSerializer < ApiSerializer

      attributes :id, :rating, :review, :created_at, 
                 :acknowledged, :email, :phone, :subject,
                 :acknowledgement_comment, :acknowledged_at,
                 :acknowledged_by
      
      # The acknowledgement comment for this feedback
      def acknowledgement_comment
        comment.try(:comment)
      end
      
      # The date of acknowledgement for this feedback
      def acknowledged_at
        comment.try(:updated_at)
      end
      
      # The full name of the acknowledging user
      def acknowledged_by
        commenter = comment.try(:commenter)
        commenter_name = commenter.try(:full_name)
        commenter_name.present? ? commenter_name : commenter.try(:email)
      end
      
      private
      
      # Pulls out the first comment object
      def comment
        object.comments.first
      end        

    end
  end
end
