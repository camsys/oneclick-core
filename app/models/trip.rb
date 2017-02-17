class Trip < ApplicationRecord
  belongs_to :user
  has_many :itineraries, dependent: :destroy
  belongs_to :origin, class_name: 'Waypoint', foreign_key: :origin_id, dependent: :destroy
  belongs_to :destination, class_name: 'Waypoint', foreign_key: :destination_id, dependent: :destroy

  accepts_nested_attributes_for :origin
  accepts_nested_attributes_for :destination

end
