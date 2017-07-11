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
  scope :containing, -> (geom2) { where("ST_Contains(geom, ?)", geom2) }
  scope :origin_for, -> (trip) { containing(trip.origin.geom) }
  scope :destination_for, -> (trip) { containing(trip.destination.geom) }


  ### CLASS METHODS ###
  
  # Makes a new region and builds its geometry, but does not persist to DB
  def self.build(attrs)
    new(attrs).build_geometry_from_recipe
  end


  ### INSTANCE METHODS ###
  
  # Tests if the region contains an empty geometry (but not a nil geometry)
  def empty?
    geom && geom.try(:is_empty?)
  end
  
  # Tests if the region contains the other geom object passed as an argument
  def contains?(other_geom)
    if(other_geom.is_a?(Place))
      other_geom = other_geom.to_point
    end
    geom.contains?(other_geom)
  end

  # Builds an RGeo geometry object based on the region's recipe
  def build_geometry_from_recipe
    self.geom = recipe.make
    unless recipe.errors.empty?
      recipe.errors.each do |e|
        self.errors.add(:recipe, e)
      end
    end
    return self
  end

end
