class Schedule < ApplicationRecord

  ### INCLUDES ###
  include ScheduleHelper

  ### VALIDATIONS ###
  validates_inclusion_of :day, in: SUN..SAT # 0 = Sunday .. 6 = Saturday
  validates_inclusion_of :start_time, in: 0..DAY_LENGTH # seconds since midnight
  validates_inclusion_of :end_time, in: 0..DAY_LENGTH  # seconds since midnight
  validate :start_time_must_be_before_end_time

  ### CALLBACKS ###
  after_create :create_midnight_shim, if: :ends_at_midnight?
  after_destroy :destroy_midnight_shim, if: :ends_at_midnight?

  ### ASSOCIATIONS ###
  belongs_to :service

  ### SCOPES ###
  scope :by_day, -> (day_of_week=(SUN..SAT).to_a) { where(day: day_of_week) }
  scope :midnight_shims, -> { where(start_time: 0, end_time: 0) }
  scope :for_display, -> { where.not(start_time: 0, end_time: 0).order(:day, :start_time) }

  ### INSTANCE METHODS ###

  # Returns true if schedule ends at midnight (and thus needs a midnight shim)
  def ends_at_midnight?
    end_time == DAY_LENGTH
  end

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

  private

  # Creates a 'midnight shim' -- an 0-second schedule at midnight the following day
  # -- allowing trips that start/end at midnight the following day to be valid.
  def create_midnight_shim
    Schedule.find_or_create_by(attributes_for_midnight_shim)
  end

  # Destroys any associated midnight shims
  def destroy_midnight_shim
    Schedule.where(attributes_for_midnight_shim).destroy_all
  end

  def attributes_for_midnight_shim
    {
      service: service,
      day: day.next.wday,
      start_time: 0,
      end_time: 0
    }
  end

  # Validates that start_time is at or before end_time
  def start_time_must_be_before_end_time
    errors.add(:start_time, "start time cannot be after end time") if (start_time > end_time)
  end

end
