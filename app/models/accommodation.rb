class Accommodation < ApplicationRecord

  #### Includes ####
  include CharacteristicsHelper

  ### Validations ####
  validates :code, uniqueness: true

  ### Associations ###
  has_and_belongs_to_many :users
  has_and_belongs_to_many :services

  ### Callbacks ###
  before_save :snake_casify

  ### Hash Methods ###
  # Should probably move to serializer
  def api_hash locale=Locale.first
  	{
  	  code: self.code, 
  	  name: self.name(locale.name),
      note: self.note(locale.name),
      question: self.question(locale.name)
    }
  end
end
