class FundingSource < ApplicationRecord
  belongs_to :agency

  validates_presence_of :name, :description, :agency
end
