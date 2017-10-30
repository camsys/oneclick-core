module Api
  module V2
    
    # Parent serializer for Accommodations, Eligibilities, and Purposes
    class EligibilitySerializer < Api::V2::CharacteristicSerializer
      
      # Only serialize value if this is called from a user serializer, 
      # and a user has been passed in the scope
      attribute :value, if: :user_present?
      
      # Value boolean is true if user has a UserEligibility associated with that eligibility
      def value
        UserEligibility.find_by(eligibility: object, user: scope[:user]).try(:value)
      end
                  
      def user_present?
        scope[:user].present?
      end
      
    end
  end
end
