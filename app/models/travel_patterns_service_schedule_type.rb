class TravelPatternsServiceScheduleType < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
