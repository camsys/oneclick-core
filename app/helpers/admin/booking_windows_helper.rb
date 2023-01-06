module Admin::BookingWindowsHelper
  def hours_for_select
    options = (0..23).map { |hour|
      meridian = hour / 12 >= 1 ? "PM" : "AM"
      show_hour = hour % 12
      show_hour = 12 if show_hour == 0
      ["#{show_hour}:00 #{meridian}" ,hour]
    }
  end
end