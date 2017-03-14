class County < ApplicationRecord
  include GeoKitchen

  validates_presence_of :name, :state

  # Returns a GeoIngredient refering to this county
  def to_geo
    GeoIngredient.new('County', name: name, state: state)
  end

  def to_s
    "#{name}, #{state}"
  end

  def self.search(term)
    where('CONCAT_WS(\', \', LOWER(name), LOWER(state)) LIKE :term', term: "%#{term.downcase}%")
  end

end
