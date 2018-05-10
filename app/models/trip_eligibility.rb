class TripEligibility < ApplicationRecord

  validates_presence_of :trip, :eligibility

  belongs_to :trip 
  belongs_to :eligibility

end