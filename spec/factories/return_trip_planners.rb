FactoryGirl.define do
  factory :return_trip_planner do

    skip_create

    initialize_with do
      outbound_trip = attributes[:outbound_trip] || FactoryGirl.create(:booked_trip)
      return_trip_attrs = attributes[:return_trip_attrs] || {}
      options = attributes[:options] || {}
      ReturnTripPlanner.new(outbound_trip, return_trip_attrs, options)
    end

  end
end
