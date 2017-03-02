FactoryGirl.define do
  factory :service, class: 'Service' do
    name "Test Service"
    logo Rails.root.join("spec/files/mbta.png").open
    email "test_service@camsys.com"
    phone "(555)555-5555"
    url "http://www.test-service-url.com"
    type "Paratransit"

    factory :different_service, class: 'Service' do
      name "Test Service 2"
      logo Rails.root.join("spec/files/parrot.gif").open
      email "test_service2@camsys.com"
      phone "(555)555-5556"
      url "http://www.test-service-url2.com"
    end
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
      after(:create) do |s|
        s.accommodations << create(:wheelchair)
        s.accommodations << create(:stretcher)
        s.accommodations << create(:jacuzzi)
      end
    end

    trait :strict do
      after(:create) do |s|
        s.eligibilities << create(:eligibility)
      end
    end
  end

end
