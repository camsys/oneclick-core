FactoryBot.define do
  factory :multiday_trip_planner do

    skip_create

    initialize_with do
      trip = attributes[:trip] || FactoryBot.create(:trip)
      options = attributes[:options] || {}
      trip_times = attributes[:trip_times] || [
          DateTime.current, 
          DateTime.current + 2.hours, 
          DateTime.current + 1.day, 
          DateTime.current + 2.days + 1.hour
        ]
      MultidayTripPlanner.new(trip, trip_times, options)
    end

  end
end
