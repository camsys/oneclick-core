class Purpose < ApplicationRecord

  #### Includes ####
  include CharacteristicsHelper 

  ### ASSOCIATIONS
  belongs_to :agency
  has_many :trips
  has_and_belongs_to_many :services

  before_save :snake_casify, if: :has_code?

  def has_code?
    code.present?
  end

end
