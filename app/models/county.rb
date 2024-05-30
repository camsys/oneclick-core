class County < GeographyRecord
  include LeafletAmbassador

  make_attribute_mappable :geom
  has_many :services

  validates_presence_of :name, :state
  acts_as_geo_ingredient attributes: [:name, :state, :buffer]

  def to_s
    "#{name}, #{state}"
  end

  # Returns a GeoIngredient refering to this county
  def to_geo
    GeoIngredient.new('County', name: name, state: state, buffer: 0)
  end

  def self.search(term)
    where('CONCAT_WS(\', \', LOWER(name), LOWER(state)) LIKE :term', term: "%#{term.downcase}%")
  end

end
