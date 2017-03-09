class Region < ApplicationRecord
  include GeoKitchen

  ### Attributes ###
  serialize :recipe, GeoRecipe
  validates :recipe, geo_recipe: true

  ### Callbacks ###
  before_save :build_geometry_from_recipe

  ### Methods ###

  # # Custom getter for recipe column returns a GeoRecipe object
  # def recipe
  #   GeoRecipe.new(@recipe)
  # end

  private

  def build_geometry_from_recipe
    self.geom = recipe.make
  end

end
