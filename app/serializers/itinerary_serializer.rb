class ItinerarySerializer < ActiveModel::Serializer
  attributes  :id, :cost, :walk_time, :transit_time,
              :start_time, :end_time, :legs
  belongs_to :service
end
