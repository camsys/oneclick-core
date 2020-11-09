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

      def cost
        if cost == -0.01 #  -.01 is an error code for OTP. 1-Click should be updated to handle this error
          return nil
        else
          return cost
        end
      end
      
      # Translate legs based on the locale in scope
      def legs
        object.translated_legs(locale)
      end
      
    end
    
  end
end
