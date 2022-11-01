class TravelPatternPurpose < ApplicationRecord
  belongs_to :travel_pattern, inverse_of: :travel_pattern_purposes
  belongs_to :purpose

  validates_presence_of :purpose
end
