class TripSerializer < ActiveModel::Serializer
  attributes :id, :trip_time, :arrive_by, :origin_id, :destination_id, :user_id
  belongs_to :origin
  has_many :itineraries
end
