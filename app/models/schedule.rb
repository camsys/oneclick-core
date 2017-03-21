class Schedule < ApplicationRecord

  ### VALIDATIONS ###
  validates_inclusion_of :day, in: 0..6 # 0 = Sunday .. 6 = Saturday
  validates_inclusion_of :start_time, in: 0..86400 # seconds since midnight
  validates_inclusion_of :end_time, in: 0..86400 # seconds since midnight

  ### ASSOCIATIONS ###
  belongs_to :service

  ### SCOPES ###
  scope :by_day, -> (day_of_week=(0..6).to_a) { where(day: day_of_week) }

  ### CLASS METHODS ###

  # Splits schedules up if they pass over midnight, and creates valid schedules with the pieces
  def self.create_valid(schedule_hashes)
    schedule_hashes = [schedule_hashes] unless schedule_hashes.is_a?(Array)
    valid_schedules = []
    schedule_hashes.each do |s|
      day, start_time, end_time = s[:day], s[:start_time], s[:end_time]

      # Previous day schedule
      if start_time < 0
        prev_day_sched = { day: (day - 1) % 7, start_time: start_time + 86400, end_time: 86400 }
        valid_schedules << prev_day_sched
      end

      # Current day schedule
      current_day_sched = { day: day, start_time: [start_time, 0].max, end_time: [end_time, 86400].min }
      valid_schedules << current_day_sched

      # Next day schedule
      if end_time > 86400
        next_day_sched = { day: (day + 1) % 7, start_time: 0, end_time: end_time - 86400 }
        valid_schedules << next_day_sched
      end

    end
    return valid_schedules
  end

  ### INSTANCE METHODS ###

  # Returns a range of the schedule's start to end time
  def to_range
    start_time..end_time
  end

  # Returns true if the start to end time range includes the passed time
  def include?(time)
    (time.wday == day) && to_range.include?(time.in_time_zone.seconds_since_midnight)
  end

end
