class TravelPatternServiceSchedule < ApplicationRecord

  belongs_to :travel_pattern
  belongs_to :service_schedule

  validates :priority, numericality: {greater_than: 0}
end
