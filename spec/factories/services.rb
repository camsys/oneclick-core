FactoryGirl.define do
  factory :service, class: 'Service' do
    name "Test Service"
    logo Rails.root.join("spec/files/mbta.png").open
    email "test_service@camsys.com"
    phone "(555)555-5555"
    url "http://www.test-service-url.com"
    type "Paratransit"
    association :start_or_end_area, factory: :region
    association :trip_within_area, factory: :big_region

    factory :different_service, class: 'Service' do
      name "Test Service 2"
      logo Rails.root.join("spec/files/parrot.gif").open
      email "test_service2@camsys.com"
      phone "(555)555-5556"
      url "http://www.test-service-url2.com"
      association :start_or_end_area, factory: :region_2
      association :trip_within_area, factory: :big_region
    end

    factory :paratransit_service, parent: :service, class: 'Paratransit' do
      name "Test Paratransit Service"
      type "Paratransit"

      trait :no_geography do
        after(:create) do |s|
          s.start_or_end_area = nil
          s.trip_within_area = nil
          s.save
        end
      end

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

      trait :with_schedules do
        after(:create) do |s|
          (1..5).each { |i| s.schedules << FactoryGirl.create(:schedule, day: i) }
        end
      end

      trait :with_micro_schedules do
        after(:create) do |s|
          s.schedules << FactoryGirl.create(:micro_schedule)
        end
      end

      trait :medical_only do
        after(:create) do |s|
          s.purposes << create(:purpose)
        end
      end

    end

    factory :transit_service, parent: :service, class: 'Transit' do
      name "Test Transit Service"
      type "Transit"
      gtfs_agency_id "mbta"
    end

    factory :taxi_service, parent: :service, class: 'Taxi' do
      name "Taxi Test Service"
      type "Taxi"
      taxi_fare_finder_id "Boston"
      trip_within_area nil
    end

    trait :flat_fare do
      fare_structure :flat
      fare_details { { base_fare: 5.0 } }
    end

    trait :mileage_fare do
      fare_structure :mileage
      fare_details { { base_fare: 0, mileage_rate: 5.0, trip_type: :taxi } }
    end

  end

end
