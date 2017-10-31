module Api
  module V2

    class ItinerarySerializer < ApiSerializer
      
      attributes :trip_type,
        :cost,
        :walk_time,
        :transit_time,
        :walk_distance,
        :wait_time,
        :legs,
        :duration
    
      belongs_to :service
      
    end
    
  end
end
