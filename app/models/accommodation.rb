class Accommodation < ApplicationRecord

  #### Includes ####
  include EligibilityAccommodationHelper

  ### Associations ###
  has_and_belongs_to_many :users
  has_and_belongs_to_many :services

  ### Callbacks ###
  before_save :snake_casify

end
