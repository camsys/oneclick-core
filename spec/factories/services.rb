FactoryGirl.define do
  factory :service do
    name "Test Service"
    logo Rails.root.join("spec/files/mbta.png").open
    type "Transit"
  end
end
