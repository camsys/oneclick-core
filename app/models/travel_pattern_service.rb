class TravelPatternService < ApplicationRecord
  belongs_to :travel_pattern
  belongs_to :service

  validates :travel_pattern_id, uniqueness: {scope: :service_id}
end
