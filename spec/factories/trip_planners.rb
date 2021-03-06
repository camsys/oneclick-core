FactoryBot.define do
  factory :trip_planner do

    skip_create

    initialize_with do
      trip = attributes[:trip] || FactoryBot.create(:trip)
      options = attributes[:options] || {}
      TripPlanner.new(trip, options)
    end

  end
end
