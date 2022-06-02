class LandmarkSetLandmark < ApplicationRecord
  belongs_to :landmark_set
  belongs_to :landmark

  accepts_nested_attributes_for :landmark
  accepts_nested_attributes_for :landmark_set

  validates :landmark_id, uniqueness: { scope: :landmark_set_id }
end
