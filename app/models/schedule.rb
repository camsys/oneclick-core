class Schedule < ApplicationRecord

  ### INCLUDES ###
  include ScheduleHelper

  ### VALIDATIONS ###
  validates_inclusion_of :day, in: SUN..SAT # 0 = Sunday .. 6 = Saturday
  validates_inclusion_of :start_time, in: 0..DAY_LENGTH # seconds since midnight
  validates_inclusion_of :end_time, in: 0..DAY_LENGTH  # seconds since midnight

  ### ASSOCIATIONS ###
  belongs_to :service

  ### SCOPES ###
  scope :by_day, -> (day_of_week=(SUN..SAT).to_a) { where(day: day_of_week) }

  ### INSTANCE METHODS ###

  # Returns a range of the schedule's start to end time
  def to_range
    start_time..end_time
  end

  # Returns true if the start to end time range includes the passed time
  # Converts passed datetime to a time in seconds since midnight, and then shifts
  # it to the schedule's weekday, both forward and backward. If either of these
  # falls in the schedule's range, returns true.
  def include?(datetime)
    time_in_seconds = datetime.in_time_zone.seconds_since_midnight
    time_on_schedule_day_fwd = time_in_seconds + (datetime.wday - self.day).wday * DAY_LENGTH
    time_on_schedule_day_back = time_in_seconds + (self.day - datetime.wday).wday * DAY_LENGTH
    to_range.include?(time_on_schedule_day_fwd) || to_range.include?(time_on_schedule_day_back)
  end

end
