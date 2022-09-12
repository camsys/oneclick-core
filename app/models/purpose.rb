class Purpose < ApplicationRecord

  #### Includes ####
  include CharacteristicsHelper 

  ### ASSOCIATIONS
  belongs_to :agency
  has_many :trips
  has_and_belongs_to_many :services
  has_many :travel_pattern_purposes
  has_many :travel_patterns, through: :travel_pattern_purposes, dependent: :restrict_with_error

  before_save :snake_casify, if: :has_code?
  validate :name_is_present?
  validates_presence_of :agency
  validates :name, uniqueness: {scope: :agency_id}

  def has_code?
    code.present?
  end

  def name_is_present?
    errors.add(:name, :blank) if self[:name].blank?
    errors.add(:name, :taken) if Purpose.where.not(id: id).exists?(name: self[:name], agency_id: agency_id)
  end
end
