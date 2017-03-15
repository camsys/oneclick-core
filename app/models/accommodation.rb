class Accommodation < ApplicationRecord

  #### Includes ####
  include EligibilityAccommodationHelper

  ### Validations ####
  validates :code, uniqueness: true

  ### Associations ###
  has_and_belongs_to_many :users
  has_and_belongs_to_many :services

  ### Callbacks ###
  before_save :snake_casify

  ### Hash Methods ###
  def api_hash locale=Locale.first
  	{
  	  code: self.code, 
  	  name: SimpleTranslationEngine.translate(locale.name, "#{self.code.to_s}_name"), 
  	  note: SimpleTranslationEngine.translate(locale.name, "#{self.code.to_s}_note")
  	}
  end
end
