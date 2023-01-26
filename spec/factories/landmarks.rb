FactoryBot.define do
  factory :landmark do
    street_number { "201" }
    route { "Station Landing" }
    city { "Medford" }
    state { "MA" }
    zip { "02155" }
    lat { 42.401697 }
    lng { 71.081818 }
    name { "Cambridge Systematics" }
  
    factory :fenway_park do
      street_number { "4" }
      route { "Yawkey Way" }
      city { "Boston" }
      state { "MA" }
      zip { "02215" }
      lat { 42.346005 }
      lng { -71.098227 }
      name { "Fewnway Park" }
    end

  end
end
