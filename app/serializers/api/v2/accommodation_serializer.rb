module Api
  module V2
    class AccommodationSerializer < CharacteristicSerializer
      
      # Only serialize value if this is called from a user serializer, 
      # and a user has been passed in the scope
      attribute :value, if: :user_present?
      
      def value
        object.in?((scope || {})[:user].accommodations)
      end
      
      def user_present?
        (scope || {})[:user].present?
      end
      
    end
  end
end
