module Api
  module V2
    class WaypointSerializer < ApiSerializer
      attributes :name, :street_number, :route, :city, :state, :zip, 
                 :lat, :lng, :formatted_address
                 
       def formatted_address
         [
           [object.street_number, object.route].compact.join(' '),
           object.city,
           [object.state, object.zip].compact.join(' ')
         ].compact.join(', ')
       end
    end
  end
end
