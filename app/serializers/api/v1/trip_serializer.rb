module Api
  module V1

    class TripSerializer < ActiveModel::Serializer

      attributes  :trip_id, :trip_token,
                  :accommodations, :characteristics, :purposes
      has_many :itineraries

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
