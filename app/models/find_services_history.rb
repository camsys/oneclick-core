class FindServicesHistory < ApplicationRecord

  belongs_to :user

  write_to_csv with: Admin::FindServicesReportCSVWriter

  ### SCOPES ###

  # Return records before or after a given date and time
  scope :from_datetime, -> (datetime) { datetime ? where('created_at >= ?', datetime) : all }
  scope :to_datetime, -> (datetime) { datetime ? where('created_at <= ?', datetime) : all }

  # Rounds to beginning or end of day.
  scope :from_date, -> (date) { date ? from_datetime(date.in_time_zone.beginning_of_day) : all }
  scope :to_date, -> (date) { date ? to_datetime(date.in_time_zone.end_of_day) : all }

  # Geographic scope returns records that start in the passed geom
  # The geom parameter does not always serialize correctly to the geometry type, so converting to text.
  scope :origin_in, -> (geom) do
    where('ST_Within(ST_SetSRID(ST_Point(user_starting_lng, user_starting_lat), 4326), ST_GeomFromText(?, 4326))', geom.as_text)
  end
end
