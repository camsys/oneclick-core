class LandmarkSet < ApplicationRecord
  belongs_to :agency
  has_many :landmark_set_landmarks, dependent: :destroy
  has_many :landmarks, through: :landmark_set_landmarks

  accepts_nested_attributes_for :landmark_set_landmarks, allow_destroy: true, reject_if: :all_blank

  validates_presence_of :name, :agency

  def self.search(term)
    where('LOWER(name) LIKE :term', term: "%#{term.downcase}%")
  end
end
