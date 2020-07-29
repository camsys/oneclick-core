module Api
  module V2

    class TripSerializer < ApiSerializer
      
      attributes  :id, 
                  :arrive_by, 
                  :trip_time
      has_many :itineraries
      has_many :accommodations
      has_many :eligibilities
      has_many :trip_types
      has_many :purposes
      belongs_to :user
      belongs_to :origin
      belongs_to :destination
      
      def accommodations
        object.relevant_accommodations
      end

      def eligibilities
        object.relevant_eligibilities
      end

      def purposes
        object.relevant_purposes
      end

      def trip_types
        object.itineraries.map(&:trip_type).uniq.map {
            |trip_type|
          {
              code: trip_type,
              name: SimpleTranslationEngine.translate(locale, "mode_#{trip_type}_name"),
              value: true
          }
        }
      end
      
    end
    
  end
end
