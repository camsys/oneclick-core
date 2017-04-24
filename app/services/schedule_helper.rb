module ScheduleHelper

  ### CONSTANTS ###

  DAY_LENGTH = 86400  # 24 hours since midnight (in seconds)
  SUN, MON, TUE, WED, THU, FRI, SAT = 0, 1, 2, 3, 4, 5, 6 # Day of week codes

  # Every half-hour, with a pretty string and seconds since midnight
  TIMES_OF_DAY = (0..48).map {|hh| [ (Time.new(0) + hh * 1800).strftime("%l:%M %p").strip, hh * 1800 ]}

end

module IntegerScheduleMethods

  # Add a wday method to Integer to help with schedule manipulation
  def wday
    self % 7
  end

end

class Integer
  include IntegerScheduleMethods
end
