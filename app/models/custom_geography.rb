class CustomGeography < GeographyRecord
  include LeafletAmbassador

  make_attribute_mappable :geom

  validates :name, uniqueness: true
  acts_as_geo_ingredient attributes: [:name, :buffer]
  belongs_to :agency

  # Prevent deletion if in use by a region.
  def destroy
    regions = Region.all
    regions.each do |region|
      region.recipe.ingredients.each do |ingredient|
        if ingredient.model.to_s == CustomGeography.name && self.name == ingredient.attributes[:name]
          return false
        end
      end
    end

    super
  end

  # Returns a GeoIngredient refering to this custom geography
  def to_geo
    GeoIngredient.new('CustomGeography', name: name, buffer: 0)
  end
end
