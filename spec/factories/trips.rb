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
  end
end
