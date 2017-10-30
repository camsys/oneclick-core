module Api
  module V2


    # class StompingGroundSerializer < ActiveModel::Serializer
    #   attributes  :name,
    #               :street_number, :route, :city, :state, :zip,
    #               :lat, :lng
    # end

    # Places serializer API V1 (past/future trips, recent places, etc.)
    class StompingGroundSerializer < ApiSerializer
      attributes  :id, :name,
                  :address_components, :formatted_address, :geometry

      def self.collection_serialize(collection)
        ActiveModelSerializers::SerializableResource.new(collection, each_serializer: self)
      end

      def address_components
        address_components = []

        #street_number
        if object.street_number
          address_components << {long_name: object.street_number, short_name: object.street_number, types: ['street_number']}
        end

        #Route
        if object.route
          address_components << {long_name: object.route, short_name: object.route, types: ['route']}
        end

        #City
        if object.city
          address_components << {long_name: object.city, short_name: object.city, types: ["locality", "political"]}
        end

        #State
        if object.state
          address_components << {long_name: object.zip, short_name: object.zip, types: ["postal_code"]}
        end

        #Zip
        if object.zip
          address_components << {long_name: object.state, short_name: object.state, types: ["administrative_area_level_1","political"]}
        end

        return address_components

      end

      def formatted_address
        [
          [object.street_number, object.route].compact.join(' '),
          object.city,
          [object.state, object.zip].compact.join(' ')
        ].compact.join(', ')
      end

      def geometry
        {
          location: {
            lat: object.lat.to_f,
            lng: object.lng.to_f,
          }
        }
      end

    end

  end
end
