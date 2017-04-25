module Api
  module V1

    class TripSerializer < ActiveModel::Serializer

      attributes  :id, :trip_id, :user_id, :arrive_by, :trip_time,
                  :accommodations, :characteristics, :purposes
      has_many :itineraries
      belongs_to :origin
      belongs_to :destination

      def trip_id
        object.id
      end

      # FILL IN THESE METHODS AS NEEDED TO MAKE API WORK
      # def trip_token; nil end # DEPRECATE?
      def accommodations; [] end
      def characteristics; [] end

      # Get a list of relevant purposes
      def purposes
        object.purposes.uniq.collect{ |p| {name: p.name, code: p.code}}
      end

    end

  end
end
