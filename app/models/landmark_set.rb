class LandmarkSet < ApplicationRecord
  belongs_to :agency

  def self.search(term)
    where('LOWER(name) LIKE :term', term: "%#{term.downcase}%")
  end

end
