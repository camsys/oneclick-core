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
  end
end