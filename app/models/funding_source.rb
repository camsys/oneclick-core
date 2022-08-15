class FundingSource < ApplicationRecord
  belongs_to :agency

  validates_presence_of :name, :description, :agency
  validates :name, uniqueness: {scope: :agency_id}
end
