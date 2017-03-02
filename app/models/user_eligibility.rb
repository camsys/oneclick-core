class UserEligibility < ApplicationRecord
  belongs_to :user
  belongs_to :eligibility
end
