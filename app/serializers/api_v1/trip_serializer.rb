class ApiV1::TripSerializer < ActiveModel::Serializer
  attributes :id, :trip_time, :arrive_by, :user_id
  belongs_to :origin
  belongs_to :destination
  has_many :itineraries
end
