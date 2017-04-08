class Eligibility < ApplicationRecord

  #### Includes ####
  include EligibilityAccommodationHelper

  ### Validations ####
  validates :code, uniqueness: true

  ### Associations ###
  has_many :user_eligibilities, dependent: :destroy
  has_many :users, through: :user_eligibilities
  has_and_belongs_to_many :services

  ### Callbacks ###
  before_save :snake_casify

  # To Label is used by SimpleForm to Get the Label
  def to_label locale=:en
    SimpleTranslationEngine.translate(locale, "eligibility_#{self.code}_name")
  end

end
