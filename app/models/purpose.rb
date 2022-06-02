class Purpose < ApplicationRecord

  #### Includes ####
  include CharacteristicsHelper 

  ### ASSOCIATIONS
  belongs_to :agency
  has_many :trips
  has_and_belongs_to_many :services

  before_save :snake_casify, if: :has_code?
  validate :name_is_present?

  def has_code?
    code.present?
  end

  def name_is_present?
    errors.add(:name, :blank) if self[:name].blank?
  end
end
