module ScheduleHelper

  ### CONSTANTS ###

  DAY_LENGTH = 86400  # 24 hours since midnight (in seconds)
  SUN, MON, TUE, WED, THU, FRI, SAT = 0, 1, 2, 3, 4, 5, 6 # Day of week codes

  # Returns a pretty time from seconds since midnight
  def ScheduleHelper.schedule_time_to_string(secs_since_midnight)
    secs_since_midnight -= 1 if secs_since_midnight == DAY_LENGTH # Send 11:59:59PM instead of 12AM
    (Time.new(0) + secs_since_midnight).strftime("%l:%M %p").strip
  end

  # Calls the module method
  def schedule_time_to_string(secs_since_midnight)
    ScheduleHelper.schedule_time_to_string(secs_since_midnight)
  end

  # Every half-hour, with a pretty string and seconds since midnight
  TIMES_OF_DAY = (0..48).map {|hh| [ ScheduleHelper.schedule_time_to_string(hh * 1800), hh * 1800 ]}


end


# Add a wday method to Integer to help with schedule manipulation
module IntegerScheduleMethods

  def wday
    self % 7
  end

end

class Integer
  include IntegerScheduleMethods
end
