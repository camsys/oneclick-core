class TripPurpose < ApplicationRecord

  validates_presence_of :trip, :purpose

  belongs_to :trip 
  belongs_to :purpose

end