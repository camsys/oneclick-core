class TripAccommodation < ApplicationRecord

  ### Associations ###
  belongs_to :trip
  belongs_to :accommodation

end
