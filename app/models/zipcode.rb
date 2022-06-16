class Zipcode < GeographyRecord
  include LeafletAmbassador

  make_attribute_mappable :geom

  validates_presence_of :name
  acts_as_geo_ingredient attributes: [:name]
end
