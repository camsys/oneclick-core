class WaypointSerializer < ActiveModel::Serializer
  attributes  :id, :name,
              :street_number, :route, :city, :state, :zip,
              :lat, :lng
end
