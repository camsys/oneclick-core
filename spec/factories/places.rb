FactoryGirl.define do
  factory :place do
    street_number "201"
    route "Station Landing"
    city "Medford"
    state "MA"
    zip "02155"
    lat 42.401697
    lng -71.081818
    name "Cambridge Systematics"

    factory :place_2 do
      street_number "100"
      route "Cambridgepark Drive"
      city "Cambridge"
      state "MA"
      zip "02140"
      lat 42.394670
      lng -71.144785
      name "Old Cambridge Systematics"
    end
  end
end
