module ScheduleHelper

  ### CONSTANTS ###

  DAY_LENGTH = 86400  # 24 hours since midnight (in seconds)
  SUN, MON, TUE, WED, THU, FRI, SAT = 0, 1, 2, 3, 4, 5, 6 # Day of week codes

  # Returns a pretty time from seconds since midnight
  def ScheduleHelper.schedule_time_to_string(secs_since_midnight, military=false)
    if military
      (Time.new(0) + secs_since_midnight).strftime("%H:%M").strip
    else
      (Time.new(0) + secs_since_midnight).strftime("%l:%M %p").strip
    end
  end

  # Calls the module method
  def schedule_time_to_string(secs_since_midnight)
    ScheduleHelper.schedule_time_to_string(secs_since_midnight)
  end

  # Calls the module method
  def schedule_time_to_military_string(secs_since_midnight)
    ScheduleHelper.schedule_time_to_string(secs_since_midnight, military=true)
  end

  # Every half-hour, with a pretty string and seconds since midnight
  TIMES_OF_DAY = (0..48).map {|hh| [ ScheduleHelper.schedule_time_to_string(hh * 1800), hh * 1800 ]}

  # Return true if the service is open on the specified date (ignore times)
  def open_on_day? day
    schedules.where(day: day.wday).count > 0 ? true : false
  end

  def next_open_time now=Time.now

    if schedules.count == 0
      return nil
    end

    later_today  = []
    # Check to see if we are open now or later today
    schedules.where(day: now.wday).each do |sched|
      if sched.include? now # We are open right now
        return now
      elsif now.seconds_since_midnight < sched.start_time # We are open later today
        later_today << sched
      end
    end
    if later_today.count > 0 # We are open later today
      next_open = later_today.sort_by{ |s| s.start_time}.first
      return now.beginning_of_day + next_open.start_time  
    end

    # we are not open now or later today, find the next day that we are open
    next_day = now + 1.days
    count = 0
    while count < 7 do 
      scheds = schedules.where(day: next_day.wday)
      if scheds.count > 0 
        next_open = scheds.sort_by{ |s| s.start_time}.first
        return next_day.beginning_of_day + next_open.start_time
      end
      count += 1 
      next_day += 1.days
    end
  
  end

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
