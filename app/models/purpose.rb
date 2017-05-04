class Purpose < ApplicationRecord

  #### Includes ####
  include EligibilityAccommodationHelper 

  ### ASSOCIATIONS
  has_many :trips
  has_and_belongs_to_many :services

  before_save :snake_casify

  # To Label is used by SimpleForm to Get the Label
  def to_label locale=:en
  	SimpleTranslationEngine.translate(locale, "purpose_#{self.code}_name")
  end
  
  def name locale=:en
    SimpleTranslationEngine.translate(locale, "purpose_#{self.code}_name")
  end

end
