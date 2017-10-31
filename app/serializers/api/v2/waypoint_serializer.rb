module Api
  module V2
    class WaypointSerializer < ApiSerializer
      attributes :name, :street_number, :route, :city, :state, :zip, 
                 :lat, :lng, :formatted_address
    end
  end
end
