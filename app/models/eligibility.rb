class Eligibility < ApplicationRecord

  #### Includes ####
  include EligibilityAccommodationHelper 

  before_save :snake_casify

end
