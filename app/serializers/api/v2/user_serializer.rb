module Api
  module V2

    class UserSerializer < ApiSerializer
      
      attributes  :first_name, 
                  :last_name, 
                  :email,
                  :preferred_locale,
                  :trip_types
      
      has_many :eligibilities
      has_many :accommodations
      
      def eligibilities
        scope[:user] ||= object # set user in scope
        Eligibility.all
      end
      
      def accommodations
        scope[:user] ||= object # set user in scope
        Accommodation.all
      end

      def trip_types
        Trip::TRIP_TYPES.map {
          |trip_type| 
            { 
              code: trip_type,
              name: SimpleTranslationEngine.translate(locale, "mode_#{trip_type}_name"),
              value: (trip_type.to_s.in? (object.preferred_trip_types || []))
            }
        }
      end

      def preferred_locale
        locale
      end

    end
    
  end
end
