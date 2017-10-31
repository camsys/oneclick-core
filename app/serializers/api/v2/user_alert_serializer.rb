module Api
  module V2
    class UserAlertSerializer < ApiSerializer
		  
		  attributes :id, :subject, :message
      
      def subject
        object.try(:subject, locale)
      end
      
      def message
        object.try(:message, locale)
      end
    
    end
  end
end
