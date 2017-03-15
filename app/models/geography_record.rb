class GeographyRecord < ApplicationRecord

  self.abstract_class = true

  include GeoKitchen

  acts_as_geo_ingredient attributes: [:name]

  # Basic methods assume just using name as an identifying attribute
  def to_s
    name
  end

  def self.search(term)
    where('LOWER(name) LIKE :term', term: "%#{term.downcase}%")
  end

end
