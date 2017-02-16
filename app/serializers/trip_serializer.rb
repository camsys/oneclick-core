class TripSerializer < ActiveModel::Serializer
  attributes :id
  has_many :itineraries
end
