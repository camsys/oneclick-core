FactoryGirl.define do
  factory :transit do
    name "Test Transit Service"
    logo Rails.root.join("spec/files/mbta.png").open
    type "Transit"
    gtfs_agency_id "mbta"
  end
end
