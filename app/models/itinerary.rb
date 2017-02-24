class Itinerary < ApplicationRecord
  belongs_to :trip

  serialize :legs

end
