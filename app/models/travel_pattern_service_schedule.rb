class TravelPatternServiceSchedule < ApplicationRecord
  belongs_to :travel_pattern, inverse_of: :travel_pattern_service_schedules
  belongs_to :service_schedule

  scope :weekly_service_schedules, -> do
    joins(service_schedule: :service_schedule_type)
      .where(overides_other_schedules: false)
      .merge(ServiceSchedule.weekly_schedules)
  end

  scope :extra_service_schedules, -> do
    joins(service_schedule: :service_schedule_type)
      .where(overides_other_schedules: false)
      .merge(ServiceSchedule.calendar_date_schedules)
  end

  scope :reduced_service_schedules, -> do
    joins(service_schedule: :service_schedule_type)
      .where(overides_other_schedules: true)
      .merge(ServiceSchedule.calendar_date_schedules)
  end

  validates :priority, numericality: {greater_than: 0}
  validate :weekly_schedules_cannot_override
  validates_presence_of :service_schedule

  delegate :is_a_weekly_schedule?, :is_a_calendar_date_schedule?, to: :service_schedule  
  
  def weekly_schedules_cannot_override
    return true if self.overides_other_schedules == false

    type = ServiceScheduleType.joins(:service_schedules)
                              .where(service_schedules: {id: self.service_schedule_id})
                              .pluck(:name).first
    if type == ServiceScheduleType::WEEKLY_SCHEDULE
      self.errors.add(:overides_other_schedules, "cannot be true for weekly schedules")
    end
  end

  def is_a_reduced_service_schedule?
    self.overides_other_schedules && self.is_a_calendar_date_schedule?
  end

  def is_an_extra_service_schedule?
    !self.overides_other_schedules && self.is_a_calendar_date_schedule?
  end
end
