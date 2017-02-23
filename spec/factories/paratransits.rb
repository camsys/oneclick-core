FactoryGirl.define do
  factory :paratransit do
    name "Test Paratransit Service"
    logo Rails.root.join("spec/files/mbta.png").open
    type "Paratransit"
  end
end
