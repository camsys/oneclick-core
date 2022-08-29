class CustomGeography < GeographyRecord
  include LeafletAmbassador

  make_attribute_mappable :geom

  validates :name, uniqueness: true
  acts_as_geo_ingredient attributes: [:name, :buffer]
  belongs_to :agency

  # Returns a GeoIngredient refering to this custom geography
  def to_geo
    GeoIngredient.new('CustomGeography', name: name, buffer: 0)
  end
end
