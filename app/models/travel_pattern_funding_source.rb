class TravelPatternFundingSource < ApplicationRecord
  belongs_to :travel_pattern
  belongs_to :funding_source
end
