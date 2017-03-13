class Region < ApplicationRecord
  include GeoKitchen

  ### Attributes ###
  serialize :recipe, GeoRecipe

  ### Callbacks ###
  before_save :build_geometry_from_recipe

  ### Methods ###

  def map_center
    [42.394216, -71.145658]
  end

  def map_zoom
    12
  end

  def to_a
    self.geom.map do |polygon|
      unpack_polygon(polygon)
    end
  end


  private

  def unpack_polygon(polygon)
    polygon_array = []
    exterior_ring = polygon.exterior_ring.points.map do |point|
      [point.y, point.x]
    end

    polygon_array << exterior_ring

    interior_points = polygon.interior_rings.each do |ring|
      ring_array = []
      ring.points.each do |point|
        ring_array << [point.y, point.x]
      end
      polygon_array << ring_array
    end
    polygon_array
  end

  def build_geometry_from_recipe
    self.geom = recipe.make
    unless recipe.errors.empty?
      recipe.errors.each do |e|
        @errors.add(:recipe, e)
      end
    end
  end

end
