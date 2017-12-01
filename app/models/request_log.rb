# Model for storing information about API controller requests
class RequestLog < ApplicationRecord
  
  serialize :params
  
  # Return request logs before or after a given date and time
  scope :from_datetime, -> (datetime) { datetime ? where('created_at >= ?', datetime) : all }
  scope :to_datetime, -> (datetime) { datetime ? where('created_at <= ?', datetime) : all }
  
  # Rounds to beginning or end of day.
  scope :from_date, -> (date) { date ? from_datetime(date.in_time_zone.beginning_of_day) : all }
  scope :to_date, -> (date) { date ? to_datetime(date.in_time_zone.end_of_day) : all }

  write_to_csv with: Admin::RequestsReportCSVWriter
  
end
