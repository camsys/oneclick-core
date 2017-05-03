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
      def accommodations
        object.relevant_accommodations.collect{ |acc| {name: acc.name, code: acc.code, note: acc.note}}
      end
      def characteristics
        object.relevant_eligibilites.collect{ |elig| {name: elig.name, code: elig.code, note: elig.note}}
      end

      # Get a list of relevant purposes
      def purposes
        object.relevant_purposes.collect{ |tp| {name: tp.name, code: tp.code}}
      end

    end

  end
end
