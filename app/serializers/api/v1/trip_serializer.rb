module Api
  module V1

    class TripSerializer < ActiveModel::Serializer

      attributes  :trip_id, :trip_token, :user_id, :arrive_by, :trip_time,
                  :accommodations, :characteristics, :purposes
      has_many :itineraries
      belongs_to :origin
      belongs_to :destination

      def trip_id
        object.id
      end

      # FILL IN THESE METHODS AS NEEDED TO MAKE API WORK
      def trip_token; nil end
      def accommodations; [] end
      def characteristics; [] end
      def purposes; [] end

    end

  end
end
