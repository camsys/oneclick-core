class TravelPatternServiceSchedule < ApplicationRecord

  belongs_to :travel_pattern
  belongs_to :service_schedule

end
