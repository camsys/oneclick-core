class DateTime

  # Returns a DateTime range of the past 7 days
  def self.this_week
    (DateTime.current - 7.days)..DateTime.current
  end
  
end
