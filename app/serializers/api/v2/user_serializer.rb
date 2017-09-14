module Api
  module V2

    class UserSerializer < ActiveModel::Serializer
      
      attributes  :first_name, 
                  :last_name, 
                  :email,
                  :accommodations,
                  :eligibilities,
                  :preferred_locale,
                  :trip_types

      # Returns a list of the user's eligibilities
      def eligibilities
        Eligibility.all.map { 
          |elig| elig.to_hash(object.preferred_locale.try(:name)).merge(
            { 
              value: 
                UserEligibility.find_by(eligibility: elig, user: object).try(:value)
            }
          )}
      end

      # Returns a list of the user's accommodations
      def accommodations
        Accommodation.all.map { 
          |acc| acc.to_hash(object.preferred_locale.try(:name)).merge(
            { 
              value: (acc.in? object.accommodations)
            }
          )}
      end

      def trip_types
        Trip::TRIP_TYPES.map {
          |trip_type| 
            { 
              code: trip_type,
              name: SimpleTranslationEngine.translate(object.preferred_locale.try(:name) || :en, "mode_#{trip_type}_name"),
              value: (trip_type.to_s.in? (object.preferred_trip_types || []))
            }
        }
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