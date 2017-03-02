class UserEligibility < ApplicationRecord

  ### Associations ###
  belongs_to :user
  belongs_to :eligibility

  ### Scopes ###
  scope :confirmed, -> { where(value: true) }
  scope :denied, -> { where(value: false) }

end
