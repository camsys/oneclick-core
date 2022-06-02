module Admin::TravelPatternsHelper
  def options_for_booking_window(agency)
    BookingWindow.where(agency: agency).pluck(:name, :id)
  end
end
