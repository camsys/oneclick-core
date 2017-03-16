class City < GeographyRecord
  validates_presence_of :name, :state
  acts_as_geo_ingredient attributes: [:name, :state]

  def to_s
    "#{name}, #{state}"
  end

  # Returns a GeoIngredient refering to this city
  def to_geo
    GeoIngredient.new('City', name: name, state: state)
  end

  def self.search(term)
    where('CONCAT_WS(\', \', LOWER(name), LOWER(state)) LIKE :term', term: "%#{term.downcase}%")
  end

end
