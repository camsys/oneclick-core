class EcolaneBookingSnapshot < ApplicationRecord
  belongs_to :booking
  belongs_to :trip
end