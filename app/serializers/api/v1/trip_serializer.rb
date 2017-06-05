module Api
  module V1

    class TripSerializer < ActiveModel::Serializer

      attributes  :id, :trip_id, :user_id, :arrive_by, :trip_time,
                  :accommodations, :characteristics, :purposes, :new_guest_user
      has_many :itineraries
      belongs_to :origin
      belongs_to :destination

      def trip_id
        object.id
      end

      # FILL IN THESE METHODS AS NEEDED TO MAKE API WORK
      # def trip_token; nil end # DEPRECATE?
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
        if object.user.guest? and object.user.trips.count == 1
          {email: object.user.email, authentication_token: object.user.authentication_token}
        else
          nil
        end
      end

    end

  end
end
