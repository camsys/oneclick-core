class CustomGeography < GeographyRecord
  include LeafletAmbassador

  make_attribute_mappable :geom

  validates :name, uniqueness: true
  acts_as_geo_ingredient attributes: [:name]
  belongs_to :agency
end
