FactoryGirl.define do
  factory :stomping_ground do
    street_number "101"
    route "Station Landing"
    city "Medford"
    state "MA"
    zip "02155"
    lat 42.401697
    lng -71.081818
    name "Work"

    factory :home_place do
      street_number "17"
      route "Park Avenue"
      city "Somerville"
      state "MA"
      zip "02144"
      lat 42.398270 
      lng -71.122898
      name "Home"
    end

    factory :cambridge_city_hall do
      street_number "795"
      route "Massachusetts Ave"
      city "Cambridge"
      state "MA"
      zip "02139"
      lat 42.367129
      lng -71.105653
      name "Cambridge City Hall"
    end
  end
end