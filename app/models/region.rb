class Region < ApplicationRecord
  include GeoKitchen
  include LeafletAmbassador

  ### ATTRIBUTES & ASSOCIATIONS ###
  serialize :recipe, GeoRecipe
  make_attribute_mappable :geom
  has_many :fare_zones
  has_many :fare_zone_services, through: :fare_zones, source: :service

  ### CALLBACKS ###
  before_save :build_geometry_from_recipe

  ### SCOPES ###
  scope :containing, -> (geom2) { where("ST_Contains(geom, ?)", geom2.to_s) }
  scope :origin_for, -> (trip) { containing(trip.origin.to_point) }
  scope :destination_for, -> (trip) { containing(trip.destination.to_point) }

  ### INSTANCE METHODS ###
  def contains?(other_geom)
    if(other_geom.is_a?(Place))
      other_geom = other_geom.to_point
    end
    geom.contains?(other_geom)
  end

  private

  def build_geometry_from_recipe
    self.geom = recipe.make
    unless recipe.errors.empty?
      recipe.errors.each do |e|
        self.errors.add(:recipe, e)
      end
    end
  end

end
