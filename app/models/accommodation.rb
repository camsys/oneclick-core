class Accommodation < ApplicationRecord
  
  #### Includes ####
  include EligibilityAccommodationHelper 

  before_save :snake_casify

end
