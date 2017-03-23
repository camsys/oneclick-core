class Trip < ApplicationRecord
  belongs_to :user
  has_many :itineraries, dependent: :destroy
  has_many :services, through: :itineraries
  belongs_to :origin, class_name: 'Waypoint', foreign_key: :origin_id, dependent: :destroy
  belongs_to :destination, class_name: 'Waypoint', foreign_key: :destination_id, dependent: :destroy
  belongs_to :selected_itinerary, class_name: "Itinerary", foreign_key: :selected_itinerary_id

  accepts_nested_attributes_for :origin
  accepts_nested_attributes_for :destination

  def unselect
    self.update(selected_itinerary: nil)
  end

end
