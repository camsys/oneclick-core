module Api
  module V2

    class TripSerializer < ActiveModel::Serializer
      
      attributes  :id, 
                  :arrive_by, 
                  :trip_time,
                  :accommodations,
                  :eligibilities,
                  :purposes
      has_many :itineraries
      belongs_to :user
      belongs_to :origin
      belongs_to :destination
      
      def accommodations
        (object.relevant_accommodations || []).map(&:to_hash)
      end

      def eligibilities
        (object.relevant_eligibilities || []).map(&:to_hash)
      end

      def purposes
        (object.relevant_purposes || []).map(&:to_hash)
      end
      
    end
    
  end
end
