class DateTime

  # Returns a DateTime range of the past 7 days. 
  # Goes from midnight (start of day) to midnight (end of day), covering a 7-day stretch
  def self.this_week
    (DateTime.current.in_time_zone.beginning_of_day - 6.days)..DateTime.current.in_time_zone.end_of_day
  end
  
end
