include GeoKitchen

FactoryGirl.define do

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

  end

end
