class Trip < ApplicationRecord
  belongs_to :user
  has_many :itineraries, dependent: :destroy
  belongs_to :origin, class_name: 'Place', foreign_key: :origin_id, dependent: :destroy
  belongs_to :destination, class_name: 'Place', foreign_key: :destination_id, dependent: :destroy
end
