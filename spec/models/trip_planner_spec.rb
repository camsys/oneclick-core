require 'rails_helper'

RSpec.describe TripPlanner do
  before(:each) { create(:otp_config) }
  before(:each) { create(:tff_config) }
  let(:trip) {create :trip}
  let!(:paratransit) { create(:paratransit_service) }
  let!(:taxi) { create(:taxi_service) }
  let!(:uber) { create(:uber_service) }
  let!(:transit) { create(:transit_service)}

  # OTP RESPONSES
  let!(:otp_responses) { {
    car: JSON.parse(File.read("spec/files/otp_response_car.json")),
    transit: JSON.parse(File.read("spec/files/otp_response_transit.json")),
    walk: JSON.parse(File.read("spec/files/otp_response_walk.json")),
    bicycle: JSON.parse(File.read("spec/files/otp_response_bicycle.json")),
    error: JSON.parse(File.read("spec/files/otp_response_error.json"))
  } }

  # OTP AMBASSADORS WITH STUBBED HTTP REQUEST BUNDLERS
  let!(:otps) do
    otp_responses.map do |tt, resp|
      [tt, create(:otp_ambassador, http_request_bundler: object_double(HTTPRequestBundler.new, response: resp, make_calls: {}, add: true))]
    end.to_h
  end

  # TRIP PLANNERS
  let(:generic_trip_planner) { create(:trip_planner, options: {router: otps[:car]}) }
  let(:transit_tp) { create(:trip_planner, options: {router: otps[:transit]})}
  let(:paratransit_tp) { create(:trip_planner, options: {router: otps[:car]})}
  let(:taxi_tp) { create(:trip_planner, options: {router: otps[:car]})}
  let(:walk_tp) { create(:trip_planner, options: {router: otps[:walk]})}
  let(:bicycle_tp) { create(:trip_planner, options: {router: otps[:bicycle]})}
  let(:car_tp) { create(:trip_planner, options: {router: otps[:car]})}
  let(:error_tp) { create(:trip_planner, options: {router: otps[:error]})}

  it 'should have trip, options, otp, and errors attributes' do
    expect(generic_trip_planner).to respond_to(:trip, :options, :router, :errors)
  end

  it 'builds transit itineraries' do
    transit_tp.prepare_for_plan_call
    itins = transit_tp.build_transit_itineraries
    expect(itins).to be_an(Array)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'builds paratransit itineraries' do
    paratransit_tp.prepare_for_plan_call
    itins = paratransit_tp.build_paratransit_itineraries
    expect(itins).to be_an(Array)
    expect(itins.count).to eq(Paratransit.count)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'builds taxi itineraries' do
    taxi_tp.prepare_for_plan_call
    itins = taxi_tp.build_taxi_itineraries
    expect(itins).to be_an(Array)
    expect(itins.count).to eq(Taxi.count)
    expect(itins.first['trip_type']).to eq('taxi')
  end

  it 'builds walk itineraries' do
    walk_tp.prepare_for_plan_call
    itins = walk_tp.build_walk_itineraries
    expect(itins).to be_an(Array)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'builds bicycle itineraries' do
    bicycle_tp.prepare_for_plan_call
    itins = bicycle_tp.build_bicycle_itineraries
    expect(itins).to be_an(Array)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'builds car itineraries' do
    car_tp.prepare_for_plan_call
    itins = car_tp.build_car_itineraries
    expect(itins).to be_an(Array)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'plans a trip, populating it with itineraries' do
    expect(generic_trip_planner.trip.itineraries.count).to eq(0)
    generic_trip_planner.plan
    expect(generic_trip_planner.trip.itineraries.count).to be > 0
  end

  it 'all itineraries have transit_time populated' do
    generic_trip_planner.plan
    expect(generic_trip_planner.trip.itineraries.all? {|i| i.transit_time.is_a?(Integer)}).to be true
  end

  it 'handles errors' do
    error_tp.plan
    expect(error_tp.errors.count).to be > 0
  end

  it 'associates fixed itineraries with services when appropriate' do
    transit_tp.prepare_for_plan_call
    itins = transit_tp.build_transit_itineraries
    itins.each do |itin|
      expect(itin['service_id']).to eq(transit.id)
    end

    walk_tp.prepare_for_plan_call
    itins = walk_tp.build_walk_itineraries
    itins.each do |itin|
      expect(itin['service_id']).to be_nil
    end
  end

end
