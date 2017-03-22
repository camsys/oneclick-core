module ScheduleHelper

  # Some useful constants
  DAY_LENGTH = 86400  # 24 hours since midnight (in seconds)
  SUN, MON, TUE, WED, THU, FRI, SAT = 0, 1, 2, 3, 4, 5, 6 # Day of week codes

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
