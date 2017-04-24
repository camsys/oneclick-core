module Api
  module V1

    # Places serializer for past and future trips calls
    class MyTripsWaypointSerializer < ActiveModel::Serializer
      attributes  :id, :name,
                  :address_components, :formatted_address, :geometry

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
        address = ""
        if object.street_number
          address += object.street_number + ', '
        end

        if object.route
          address += object.route + ', '
        end

        if object.city
          address += object.city + ', '
        end

        if object.state
          address += object.state + '  '
        end

        if object.zip
          address += object.zip + '  '
        end

        return address.chop.chop
      end

      def geometry
        {
          location: {
            lat: object.lat,
            lng: object.lng,
          }
        }
      end

    end

  end
end
