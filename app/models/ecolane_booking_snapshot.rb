class EcolaneBookingSnapshot < ApplicationRecord
  belongs_to :booking, class_name: 'EcolaneBooking'
end