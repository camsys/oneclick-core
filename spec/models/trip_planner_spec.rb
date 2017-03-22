require 'rails_helper'

RSpec.describe TripPlanner do
  # before(:each) { Config.create(key: "open_trip_planner", value: "http://otp-ma.camsys-apps.com:8080/otp/routers/default") unless Config.open_trip_planner}
  let(:trip) {create :trip}
  let!(:taxi) { FactoryGirl.create :taxi_service } 

  # Mock an OTP Ambassador with stubbed methods
  let(:otp) do
    double('otp',
      get_itineraries: {itineraries: [attributes_for(:transit_itinerary)]},
      get_duration: attributes_for(:paratransit_itinerary)[:transit_time]
    )
  end

  # Mock an OTP Ambassador with stubbed methods
  let(:tff) do
    double('tff',
      fare: 10,
    )
  end

  # Make a Trip Planner and pass it the mocked up OTP Ambassador
  let(:trip_planner) do
    TripPlanner.new(trip, modes: ['transit', 'paratransit', 'taxi'], router: otp, taxi_ambassador: tff)
  end

  it 'should have trip, options, otp, and errors attributes' do
    expect(trip_planner).to respond_to(:trip, :options, :router, :errors)
  end

  it 'builds transit itineraries' do
    itins = trip_planner.build_transit_itineraries
    expect(itins).to be_an(Array)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'builds paratransit itineraries' do
    itins = trip_planner.build_paratransit_itineraries
    expect(itins).to be_an(Array)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'builds taxi itineraries' do
    itins = trip_planner.build_taxi_itineraries
    expect(itins).to be_an(Array)
    expect(itins.count).to be(1)
    expect(itins.first['trip_type']).to eq('taxi')
    expect(itins.first['cost']).to eq(10)
  end

  it 'plans a trip, populating it with itineraries' do
    expect(trip_planner.trip.itineraries.count).to eq(0)
    trip_planner.plan
    expect(trip_planner.trip.itineraries.count).to be > 0
  end

  it 'all itineraries have transit_time populated' do
    trip_planner.plan
    expect(trip_planner.trip.itineraries.all? {|i| i.transit_time.is_a?(Integer)}).to be true
  end

end
