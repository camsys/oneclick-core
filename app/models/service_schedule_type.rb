class ServiceScheduleType < ApplicationRecord
  WEEKLY_SCHEDULE = "Weekly pattern"
  CALENDAR_DATE_SCHEDULE = "Selected calendar dates"

  has_many :service_schedules

  scope :weekly_schedule_type, -> { where(name: WEEKLY_SCHEDULE) }
  scope :calendar_date_schedule_type, -> { where(name: CALENDAR_DATE_SCHEDULE) }

  validates :name, presence: true, uniqueness: true

  def is_a_weekly_schedule?
    self.name == ServiceScheduleType::WEEKLY_SCHEDULE
  end

  def is_a_calendar_date_schedule?
    self.name == ServiceScheduleType::CALENDAR_DATE_SCHEDULE
  end

  def self.weekly_schedule
    self.find_by(name: ServiceScheduleType::WEEKLY_SCHEDULE)
  end

  def self.calendar_date_schedule
    self.find_by(name: ServiceScheduleType::CALENDAR_DATE_SCHEDULE)
  end
end
