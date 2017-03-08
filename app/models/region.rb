class Region < ApplicationRecord

  ### Attributes ###
  serialize :recipe
  validate :recipe_is_valid

  ### Callbacks ###
  before_save :build_geometry_from_recipe

  private

  # @@VALID_GEOGRAPHIES = [:counties, :zipcodes, :cities]

  # Custom validator determines that recipe is a hash with arrays as key values
  def recipe_is_valid
    if recipe.is_a?(Hash)
      if recipe.values.all?{|v| v.is_a?(Array)}
        if recipe.values.flatten.all?{|el| el.is_a?(Hash)}
        else
          @errors.add(:recipe, "Geography type array elements must all be hashes")
        end
      else
        @errors.add(:recipe, "Each geography type must have an array as value")
      end
    else
      @errors.add(:recipe, "Must be a hash of geography types")
    end
  end

  # This custom constructor parses the recipe hash and builds a geometry
  # from it by unioning all the nested geoms into a single multi_polygon
  def build_geometry_from_recipe
    self.geom = recipe.map do |type, areas|
      geo_model = type.to_s.classify.constantize
      geoms = areas.map {|area| geo_model.find_by(area).geom }
      geoms.reduce { |combined_area, geom| combined_area.union(geom) }
    end.reduce { |combined_area, geom| combined_area.union(geom) }
  end

end
