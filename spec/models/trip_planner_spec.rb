require 'rails_helper'

RSpec.describe TripPlanner do
  # before(:each) { Config.create(key: "open_trip_planner", value: "http://otp-ma.camsys-apps.com:8080/otp/routers/default") unless Config.open_trip_planner}
  let(:trip) {create :trip}

  # Mock an OTP Ambassador with stubbed methods
  let(:otp) do
    double('otp',
      get_transit_itineraries: {itineraries: [attributes_for(:transit_itinerary)]},
      drive_time: attributes_for(:paratransit_itinerary)[:transit_time]
    )
  end

  # Make a Trip Planner and pass it the mocked up OTP Ambassador
  let(:trip_planner) do
    TripPlanner.new(trip, modes: ['transit', 'paratransit', 'taxi'], router: otp)
  end

  it 'should have trip, options, otp, and errors attributes' do
    expect(trip_planner).to respond_to(:trip, :options, :router, :errors)
  end

  it 'builds transit itineraries' do
    itins = trip_planner.transit_itineraries
    expect(itins).to be_an(Array)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'builds paratransit itineraries' do
    itins = trip_planner.paratransit_itineraries
    expect(itins).to be_an(Array)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'plans a trip, populating it with itineraries' do
    expect(trip_planner.trip.itineraries.count).to eq(0)
    trip_planner.plan
    expect(trip_planner.trip.itineraries.count).to be > 0
  end

  it 'paratransit itineraries have transit_time populated' do
    trip_planner.plan
    expect(trip_planner.trip.itineraries[0].transit_time).to be_an(Integer)
  end

end
