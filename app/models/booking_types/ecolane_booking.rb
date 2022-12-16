class EcolaneBooking < Booking
  # This list may not be complete.
  # TODO: Need to find Ecolane's documentation to verify complete list
  ECOLANE_STATUSES = [
    "canceled",
    "completed",
    "ordered",
    " noshow",
    "noshow",
    "dispatch",
    nil,
    "active"
  ].freeze

  BOOKED_TRIP_STATUS_CODES = [
    "completed", "ordered", "dispatch", "active"
  ].freeze

  CANCELED_TRIP_STATUS_CODES = [
    "canceled", " noshow", "noshow", "canceled_without_confirmation"
  ].freeze

  scope :booked, -> { where.not(confirmation: nil, status: CANCELED_TRIP_STATUS_CODES) }
  scope :not_booked, -> { where(confirmation: nil).or(where(status: ECOLANE_STATUSES - BOOKED_TRIP_STATUS_CODES)) }

  # Checking for a confirmation code seems more reliable than checking a possibly incomplete list of statuses
  def booked?
    confirmation.present? && !self.canceled?
  end

  def canceled?
    CANCELED_TRIP_STATUS_CODES.include?(status)
  end
end