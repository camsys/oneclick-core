class CustomGeography < GeographyRecord
  validates :name, uniqueness: true
  acts_as_geo_ingredient attributes: [:name]
  belongs_to :agency
end
