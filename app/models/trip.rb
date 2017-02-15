class Trip < ApplicationRecord
  belongs_to :user
  has_many :itineraries, dependent: :destroy
  belongs_to :origin, class_name: 'Waypoint', foreign_key: :origin_id, dependent: :destroy
  belongs_to :destination, class_name: 'Waypoint', foreign_key: :destination_id, dependent: :destroy

  accepts_nested_attributes_for :origin
  accepts_nested_attributes_for :destination


  # Build itineraries before_create? or around_create?
  # Use options passed along with trip.create to decide which itineraries to build and how
  # OR, create a custom plan method that calls create internally
  # Perhaps create a TripPlanner PORO to handle creating trips and building itineraries for them

end
