FactoryGirl.define do
  factory :service, class: 'Service' do
    name "Test Service"
    logo Rails.root.join("spec/files/mbta.png").open
    email "test_service@camsys.com"
    phone "(555)555-5555"
    url "http://www.test-service-url.com"
    type "Transit"
  end

  factory :transit_service, parent: :service, class: 'Transit' do
    name "Test Transit Service"
    type "Transit"
    gtfs_agency_id "mbta"
  end

  factory :paratransit_service, parent: :service, class: 'Paratransit' do
    name "Test Paratransit Service"
    type "Paratransit"

    trait :accommodating do
      after(:create) do |svc|
        svc.accommodations << create(:wheelchair)
        svc.accommodations << create(:stretcher)
        svc.accommodations << create(:jacuzzi)
      end
    end
  end

end
