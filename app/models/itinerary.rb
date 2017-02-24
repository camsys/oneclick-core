class Itinerary < ApplicationRecord
  belongs_to :trip
  belongs_to :service

  serialize :legs

end
