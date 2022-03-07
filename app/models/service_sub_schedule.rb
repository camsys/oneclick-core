class ServiceSubSchedule < ApplicationRecord
  ### INCLUDES ###
  include ScheduleHelper

  ### VALIDATIONS ###
  validates_inclusion_of :day, in: SUN..SAT # 0 = Sunday .. 6 = Saturday
  validates_inclusion_of :start_time, in: 0..DAY_LENGTH # seconds since midnight
  validates_inclusion_of :end_time, in: 0..DAY_LENGTH  # seconds since midnight
  validate :start_time_must_be_before_end_time

  ### CALLBACKS ###
  # after_create :create_midnight_shim, if: :ends_at_midnight?
  after_save :ensure_midnight_shim, if: :ends_at_midnight?
  after_destroy :destroy_midnight_shim, if: :ends_at_midnight?

  belongs_to :service_schedule

  ### SCOPES ###
  scope :by_day, -> (day_of_week=(SUN..SAT).to_a) { where(day: day_of_week) }
  scope :midnight_shims, -> { where(start_time: 0, end_time: 0) }
  scope :for_display, -> { where.not(id: midnight_shims.pluck(:id)).order(:calendar_date, :day, :start_time) }
  scope :overlapping_with, -> (sched) do
    by_day(sched.day).where(start_time: sched.to_range).where.not(id: sched.id)
  end


  ### CLASS METHODS ###

  # Consolidates schedules in the collection with overlapping dates & times
  def self.build_consolidated
    for_save = []

    # Group by day of week and sort each group by start time
    (0..6).map { |d| all.where(day: d).order(:start_time) }
        .each do |scheds|  # For each day of the week, iterate through and consolidate schedules
      # Start with the earliest, and combine with other schedules that overlap
      next unless scheds.present?
      for_save << scheds.reduce(scheds.first.dup) do |new_sched, sch|
        if new_sched.to_range.overlaps?(sch.to_range) # If the schedule starts before the new_sched ends, update end_time
          new_sched.end_time = [new_sched.end_time, sch.end_time].max
        else # Otherwise, save the new_sched and make a new one
          for_save << new_sched
          new_sched = sch.dup
        end
        next new_sched
      end
    end

    return for_save.compact
    # Destroy the old schedules if the new ones save successfully
    # for_destroy = Schedule.for_display.pluck(:id)
    # Schedule.where(id: for_destroy).destroy_all if for_save.compact.all?(&:save)
  end


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
  def ensure_midnight_shim
    ServiceSubSchedule.find_or_create_by(attributes_for_midnight_shim)
  end

  # Destroys any associated midnight shims unless another midnight-ending schedule exists
  def destroy_midnight_shim
    unless ServiceSubSchedule.where(service_schedule: service_schedule, day: day, end_time: DAY_LENGTH).present?
      ServiceSubSchedule.where(attributes_for_midnight_shim).destroy_all
    end
  end

  def attributes_for_midnight_shim
    {
        service_schedule: service_schedule,
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
