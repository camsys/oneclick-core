FactoryGirl.define do
  factory :trip do
    user
    association :origin, factory: :waypoint_02139
    association :destination, factory: :waypoint_02140
    trip_time DateTime.new(2020, 7, 14, 14) # Tuesday, 10am EST
    arrive_by true

    factory :guest_trip do
      user nil
    end

    factory :trip_with_itins do
      after(:create) do |trip|
        create(:itinerary, trip: trip)
      end
    end

    factory :trip_with_paratransit_itins do
      after(:create) do |trip|
        create(:paratransit_itinerary, trip: trip)
      end
    end

    factory :trip_with_strict_and_accommodating_paratransit_itins do
      after(:create) do |trip|
        create(:strict_and_accommodating_paratransit_itinerary, trip: trip)
      end
    end

    trait :weekday_day do
      # puts "TIME ZONE: ", Time.zone.to_s
      trip_time DateTime.new(2020, 7, 14, 17) # Tuesday, 12pm EST
    end

    trait :weekday_night do
      trip_time DateTime.new(2020, 7, 15, 3, 30) # Tuesday, 11pm EST
    end

    trait :weekend_day do
      trip_time DateTime.new(2020, 7, 12, 17) # Tuesday, 12pm EST
    end

    trait :weekend_night do
      trip_time DateTime.new(2020, 7, 13, 3, 30) # Sunday, 11pm EST
    end

    trait :going_to_see_metallica do |t|
      association :purpose, factory: :metallica_concert
    end

  end
end
