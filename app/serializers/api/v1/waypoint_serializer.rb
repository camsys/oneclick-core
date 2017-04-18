module Api
  module V1


    class WaypointSerializer < ActiveModel::Serializer
      attributes  :name,
                  :street_number, :route, :city, :state, :zip,
                  :lat, :lng
    end

  end
end
