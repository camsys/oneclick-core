include GeoKitchen

FactoryBot.define do

  factory :region do
    recipe do
      GeoRecipe.new([Zipcode.find_by(name: "02139").to_geo])
    end

    factory :region_2 do
      recipe do
        GeoRecipe.new([Zipcode.find_by(name: "02140").to_geo])
      end
    end

    factory :big_region do
      recipe do
        GeoRecipe.new([City.find_by(name: "Cambridge", state: "MA").to_geo])
      end
    end

    factory :combined_region do
      recipe do
        GeoRecipe.new([
          County.find_by(name: "Essex", state: "MA").to_geo,
          City.find_by(name: "Boston", state: "MA").to_geo,
          Zipcode.find_by(name: "02139").to_geo
        ])
      end
    end

  end

end
