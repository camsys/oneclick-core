class Eligibility < ApplicationRecord

  #### Includes ####
  include EligibilityAccommodationHelper

  ### Associations ###
  has_many :user_eligibilities, dependent: :destroy
  has_many :users, through: :user_eligibilities
  has_and_belongs_to_many :services

  ### Callbacks ###
  before_save :snake_casify

end
