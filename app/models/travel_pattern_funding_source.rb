class TravelPatternFundingSource < ApplicationRecord
  belongs_to :travel_pattern, inverse_of: :travel_pattern_funding_sources
  belongs_to :funding_source

  validates_presence_of :funding_source
end
