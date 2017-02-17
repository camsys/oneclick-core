FactoryGirl.define do
  factory :trip do
    user
    association :origin, factory: :waypoint_2
    association :destination, factory: :waypoint
    trip_time DateTime.new(2020)
    arrive_by true

    factory :guest_trip do
      user nil
    end

    factory :trip_with_itins do
      after(:create) do |trip|
        create(:itinerary, trip: trip)
      end
    end

  end
end
