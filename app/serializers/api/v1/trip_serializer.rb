module Api
  module V1

    class TripSerializer < ActiveModel::Serializer

      attributes  :id, :trip_id, :user_id, :arrive_by, :trip_time,
                  :accommodations, :characteristics, :purposes, :new_guest_user, :itineraries
      #has_many :itineraries
      belongs_to :origin
      belongs_to :destination

      def trip_id
        object.id
      end

      # FILL IN THESE METHODS AS NEEDED TO MAKE API WORK
      # def trip_token; nil end # DEPRECATE?
      
      # In in API V1, round trips are not broken into 2 trips.  A single trip is returned will all the itineraries.
      # The segment_index is used to differentiate between outbound and return trips. 
      def itineraries
        if object.next_trip 
          (object.itineraries + object.next_trip.itineraries).map{ |x| ItinerarySerializer.new(x) }
        else 
          (object.itineraries).map{ |x| ItinerarySerializer.new(x) }
        end
      end

      def accommodations
        object.relevant_accommodations ? object.relevant_accommodations.collect{ |acc| {name: acc.name, code: acc.code, note: acc.note}} : []
      end

      def characteristics
        object.relevant_eligibilities ? object.relevant_eligibilities.collect{ |elig| {name: elig.name, code: elig.code, note: elig.note}} : []
      end

      # Get a list of relevant purposes
      def purposes
        object.relevant_purposes ? object.relevant_purposes.collect{ |tp| {name: tp.name, code: tp.code}} : []
      end

      # If this trip is a new guest user, return the email and token
      def new_guest_user
        if object.user && object.user.guest? && object.user.trips.count == 1
          {email: object.user.email, authentication_token: object.user.authentication_token}
        else
          nil
        end
      end

    end

  end
end
