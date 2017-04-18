FactoryGirl.define do
  factory :waypoint do
    street_number "201"
    route "Station Landing"
    city "Medford"
    state "MA"
    zip "02155"
    lat 42.401697
    lng -71.081818
    name "Cambridge Systematics"

    factory :waypoint_02139 do
      zip "02139"
      lat 42.365047
      lng -71.103359
      name "Central Square"
    end

    factory :waypoint_02140 do
      street_number "100"
      route "Cambridgepark Drive"
      city "Cambridge"
      state "MA"
      zip "02140"
      lat 42.394670
      lng -71.144785
      name "Old Cambridge Systematics"
    end

    factory :way_out_point do
      street_number "555"
      route "12th St"
      city "Oakland"
      state "CA"
      zip "94607"
      lat 37.803380
      lng -122.275297
      name "Cambridge Systematics Oakland Office"
    end

    factory :way_out_point_2 do
      street_number "515"
      route "S Figueroa St"
      city "Los Angelese"
      state "CA"
      zip "90071"
      lat 34.052191
      lng -118.258469
      name "Cambridge Systematics LA Office"
    end
  end
end
