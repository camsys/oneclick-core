class Purpose < ApplicationRecord

  #### Includes ####
  include CharacteristicsHelper 

  ### ASSOCIATIONS
  has_many :trips
  has_and_belongs_to_many :services

  before_save :snake_casify

end
