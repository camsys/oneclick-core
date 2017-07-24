module Api
  module V2

    class UserSerializer < ActiveModel::Serializer
      
      attributes  :first_name, 
                  :last_name, 
                  :email,
                  :accommodations,
                  :eligibilities,
                  :preferred_locale,
                  :preferred_trip_types

      # Returns a list of the user's eligibilities
      def eligibilities
        object.user_eligibilities.map { |ue| ue.api_hash }
      end

      # Returns a list of the user's accommodations
      def accommodations
        accs = object.accommodations.map { |acc| acc.api_hash(object.locale) }
        accs.each do |acc|
          acc[:value] = true
        end
        accs
      end

      def preferred_locale
        object.preferred_locale ? object.preferred_locale.name : 'en'
      end

      def preferred_trip_types
        #Add mode_ onto the front of the mode name.  This is done to support existing API/v1 instances.  It has been depracated
        object.preferred_trip_types
      end
        

    end
    
  end
end