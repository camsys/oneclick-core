class Geocoded < ApplicationRecord

  self.abstract_class = true

  #### Includes ####
  include GooglePlace

end
