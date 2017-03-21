class Schedule < ApplicationRecord

  ### ASSOCIATIONS ###
  belongs_to :service

  ### SCOPES ###
  scope :by_day, -> (day_of_week=(0..6).to_a) { where(day: day_of_week) }

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
