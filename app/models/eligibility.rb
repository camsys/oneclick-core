class Eligibility < ApplicationRecord

  #### Includes ####
  include CharacteristicsHelper

  ### Validations ####
  validates :code, uniqueness: true

  ### Associations ###
  has_many :user_eligibilities, dependent: :destroy
  has_many :users, through: :user_eligibilities
  has_and_belongs_to_many :services

  ### Callbacks ###
  before_save :snake_casify
  before_save :ensure_rank

  ### Scopes ###
  scope :ordered_by_rank, -> { order(ranks: :asc) }

end
