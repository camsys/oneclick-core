class UberExtension < ApplicationRecord
  #Contains extra information needed for Uber itineraries
  belongs_to :itinerary, dependent: :destroy
end
