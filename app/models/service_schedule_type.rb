class ServiceScheduleType < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
