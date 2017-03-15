include GeoKitchen

FactoryGirl.define do

  factory :region do
    recipe do
      @county = create(:county)
      @city = create(:city)
      @zipcode = create(:zipcode)
      GeoRecipe.new([@county.to_geo, @city.to_geo, @zipcode.to_geo])
    end

    factory :region_2 do
      recipe do
        @county_2 = create(:county_2)
        @county_3 = create(:county_3)
        GeoRecipe.new([@county_2.to_geo, @county_3.to_geo])
      end
    end

  end

end
