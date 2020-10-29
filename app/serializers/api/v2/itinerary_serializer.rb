module Api
  module V2

    class ItinerarySerializer < ApiSerializer
      
      attributes :id, :trip_type,
        :cost,
        :walk_time,
        :transit_time,
        :walk_distance,
        :wait_time,
        :legs,
        :duration
    
      belongs_to :service
      
      # Translate legs based on the locale in scope
      def legs
        object.translated_legs(locale)
      end
      
    end
    
  end
end
