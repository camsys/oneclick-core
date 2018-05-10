class TripAccommodation < ApplicationRecord

  validates_presence_of :trip, :accommodation 

  belongs_to :trip 
  belongs_to :accommodation

end
