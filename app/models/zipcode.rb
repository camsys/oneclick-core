class Zipcode < GeographyRecord
  include LeafletAmbassador

  make_attribute_mappable :geom

  validates_presence_of :name
  acts_as_geo_ingredient attributes: [:name, :buffer]

  # Returns a GeoIngredient refering to this zipcode
  def to_geo
    GeoIngredient.new('Zipcode', name: name, buffer: 0)
  end
end
