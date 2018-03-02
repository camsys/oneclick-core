class LyftExtension < ApplicationRecord
    #Contains extra information needed for Lyft itineraries
  belongs_to :itinerary, dependent: :destroy
end
