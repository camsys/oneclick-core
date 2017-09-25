FactoryGirl.define do
  factory :service, class: 'Service' do
    name "Test Service"
    logo Rails.root.join("spec/files/mbta.png").open
    email "test_service@camsys.com"
    phone "(555)555-5555"
    url "http://www.test-service-url.com"
    type "Paratransit"
    published true
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
      
      trait :with_overlapping_schedules do
        after(:create) do |s|
          s.schedules << FactoryGirl.create(:schedule, day: 1, start_time: 3600, end_time: 10800)
          s.schedules << FactoryGirl.create(:schedule, day: 1, start_time: 7200, end_time: 14400)
          s.schedules << FactoryGirl.create(:schedule, day: 1, start_time: 14400, end_time: 18000)
        end
      end

      trait :medical_only do
        after(:create) do |s|
          s.purposes << create(:purpose)
        end
      end
      
      trait :ride_pilot_bookable do
        booking_api "ride_pilot"
        booking_details { 
          {
            provider_id: 0
          }
        }

        after(:build) do |svc|
          svc.stub(:valid_booking_profile).and_return true
        end
      end

    end

    factory :transit_service, parent: :service, class: 'Transit' do
      name "Test Transit Service"
      type "Transit"
      gtfs_agency_id "1"
    end

    factory :taxi_service, parent: :service, class: 'Taxi' do
      name "Taxi Test Service"
      type "Taxi"
      trip_within_area nil
    end

    factory :uber_service, parent: :service, class: 'Uber' do
      name "UberX"
      type "Uber"
      trip_within_area nil
    end

    trait :flat_fare do
      fare_structure :flat
      fare_details { { flat_base_fare: 5.0 } }
    end

    trait :mileage_fare do
      fare_structure :mileage
      fare_details do
        { mileage_base_fare: 0, mileage_rate: 5.0, trip_type: :taxi }.with_indifferent_access
      end
    end

    trait :zone_fare do
      fare_structure :zone
      fare_details do
        {
          fare_zones: {
            "a" => [{"model"=>"Zipcode", "attributes"=>{"name"=>"02139"}}],
            "b" => [{"model"=>"Zipcode", "attributes"=>{"name"=>"02140"}}]
          },
          fare_table: {
            "a" => {"a"=>1.0, "b"=>2.0},
            "b"=>{"a"=>3.0, "b"=>4.0}
          }
        }.with_indifferent_access
      end
    end
    
    trait :empty_fare do
      fare_structure :empty
      fare_details { {} }
    end
    
    trait :url_fare do
      fare_structure :url
      fare_details { { url: "www.some_url_for_fare_details.gov" } }
    end

    trait :taxi_fare_finder_fare do
      fare_structure :taxi_fare_finder
      fare_details { { taxi_fare_finder_city: "Boston" }.with_indifferent_access }
    end

    trait :with_comments do
      after(:create) do |service|
        create(:comment, commentable: service)
        create(:es, commentable: service)
        create(:fr, commentable: service)
      end
    end

  end

end
