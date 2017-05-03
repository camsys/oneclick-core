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

  # To Label is used by SimpleForm to Get the Label
  def to_label locale=:en
    self.name locale
  end

  # Handy Translation Shortcuts
  def name locale=:en
    SimpleTranslationEngine.translate(locale, "accommodation_#{self.code}_name")
  end

  def note locale=:en
    SimpleTranslationEngine.translate(locale, "accommodation_#{self.code}_note")
  end

  ### Hash Methods ###
  def api_hash locale=Locale.first
  	{
  	  code: self.code, 
  	  name: SimpleTranslationEngine.translate(locale.name, "accommodation_#{self.code.to_s}_name"), 
      note: SimpleTranslationEngine.translate(locale.name, "accommodation_#{self.code.to_s}_note"),
      question: SimpleTranslationEngine.translate(locale.name, "accommodation_#{self.code.to_s}_question")
  	}
  end
end
