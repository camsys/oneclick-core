class FareZone < ApplicationRecord

  ### ASSOCIATIONS ###
  belongs_to :service
  belongs_to :region
  
end
