FactoryGirl.define do
  factory :trip do
    user
    association :origin, factory: :waypoint_2
    association :destination, factory: :waypoint
    trip_time Time.new(2020, 7, 14, 10) # Tuesday, 10am
    arrive_by true

    factory :guest_trip do
      user nil
    end

    factory :trip_with_itins do
      after(:create) do |trip|
        create(:itinerary, trip: trip)
      end
    end

    trait :weekday_day do
      # puts "TIME ZONE: ", Time.zone.to_s
      trip_time Time.new(2020, 7, 14, 12, 0, 0) # Tuesday, 12pm
    end

    trait :weekday_night do
      trip_time Time.new(2020, 7, 14, 23) # Tuesday, 11pm
    end

    trait :weekend_day do
      trip_time Time.new(2020, 7, 12, 12) # Sunday, 12pm
    end

    trait :weekend_night do
      trip_time Time.new(2020, 7, 12, 23) # Sunday, 11pm
    end


  end
end
