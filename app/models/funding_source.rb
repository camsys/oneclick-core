class FundingSource < ApplicationRecord
  belongs_to :agency
  has_many :travel_pattern_funding_sources
  has_many :travel_patterns, through: :travel_pattern_funding_sources, dependent: :restrict_with_error

  validates_presence_of :name, :description, :agency
  validates :name, uniqueness: {scope: :agency_id}
end
