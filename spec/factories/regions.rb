include GeoKitchen

FactoryGirl.define do
  factory :region do
    recipe do
      county, city, zipcode = County.last, City.last, Zipcode.last
      GeoRecipe.new([
        GeoIngredient.new('County', name: county.name, state: county.state),
        GeoIngredient.new('City', name: city.name, state: city.state),
        GeoIngredient.new('Zipcode', name: zipcode.name)
      ])
    end
  end
end
