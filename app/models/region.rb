class Region < ApplicationRecord
  include GeoKitchen

  ### Attributes ###
  serialize :recipe, GeoRecipe

  ### Callbacks ###
  before_save :build_geometry_from_recipe

  ### Methods ###

  private

  def build_geometry_from_recipe
    self.geom = recipe.make
    unless recipe.errors.empty?
      recipe.errors.each do |e|
        @errors.add(:recipe, e)
      end
    end
  end

end
