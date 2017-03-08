class Region < ApplicationRecord

  ### Attributes ###
  serialize :recipe
  validate :recipe_is_valid

  ### Callbacks ###
  after_validation :build_geometry_from_recipe

  private

  # Custom validator determines that recipe is a hash with arrays as key values
  def recipe_is_valid
    if @recipe.is_a?(Hash)
      if @recipe.values.all?{|v| v.is_a?(Array)}
        if @recipe.values.flatten.all?{|el| el.is_a?(Hash)}
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

  # This custom constructor parses the recipe hash and builds a geometry from it
  def build_geometry_from_recipe
    puts "Building Geometry from recipe", recipe
    @recipe.each |type, areas| do
      geo_model = type.to_s.classify.constantize
      areas.map {|area| geo_model.find_by(area)}
    end
  end

end
