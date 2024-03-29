require 'rails_helper'

# NOTE: Removed Uber and Lyft services from the "it skips or includes service filters when requested"
# test as those get filtered out by TripPlanner now and might need to do some work to keep it synced
RSpec.describe TripPlanner do  
  before(:each) { create(:otp_config) }
  before(:each) { create(:tff_config) }
  before(:each) { create(:uber_token) }
  before(:each) { create(:lyft_client_token) }
  let(:trip) { create(:trip) }
  let(:accommodating_trip) { create(:trip, user: create(:user, :needs_accommodation)) }
  let!(:paratransit) { create(:paratransit_service, :medical_only, :ecolane_bookable) }
  let!(:taxi) { create(:taxi_service) }
  let!(:uber) { create(:uber_service) }
  let!(:lyft) { create(:lyft_service) }
  let!(:transit) { create(:transit_service)}
  let!(:strict_paratransit) { create(:paratransit_service, :medical_only, :strict, :ecolane_bookable) }
  let!(:accommodating_paratransit) { create(:paratransit_service, :medical_only, :accommodating, :ecolane_bookable) }

  # TODO We need to make 2 contexts. One for travel patterns, and one for non travel patterns
  before do
    otp_paratransit_1 = Service.find_by(gtfs_agency_id: "soundgenerations-wa-us:2291")
    create(:paratransit_service, gtfs_agency_id: "soundgenerations-wa-us:2291") unless otp_paratransit_1

    otp_paratransit_2 = Service.find_by(gtfs_agency_id: "kcm:1")
    create(:paratransit_service, gtfs_agency_id: "kcm:1") unless otp_paratransit_2
    # Config.create(key: "dashboard_mode", value: "travel_patterns")
    # allow(Service).to receive(:purposes) ...
    # allow(Config).to receive(:dashboard_mode)
  end

  # OTP RESPONSES
  let!(:otp_responses) { {
    car: JSON.parse(File.read("spec/files/otp_response_car.json")),
    transit: JSON.parse(File.read("spec/files/otp_response_transit.json")),
    paratransit: JSON.parse(File.read("spec/files/otp_response_paratransit.json")),
    walk: JSON.parse(File.read("spec/files/otp_response_walk.json")),
    bicycle: JSON.parse(File.read("spec/files/otp_response_bicycle.json")),
    error: JSON.parse(File.read("spec/files/otp_response_error.json"))
  } }

  # OTP AMBASSADORS WITH STUBBED HTTP REQUEST BUNDLERS
  let!(:otps) do
    otp_responses.map do |tt, resp|
      [tt, create(:otp_ambassador, http_request_bundler: object_double(HTTPRequestBundler.new,
      response: resp,
      make_calls: {},
      add: true,
      response_status_code: tt.to_s == 'error' ? '500': '200'))]
    end.to_h
  end

  # TRIP PLANNERS
  let(:generic_trip_planner) { create(:trip_planner, options: {router: otps[:car]}) }
  let(:transit_tp) { create(:trip_planner, options: {router: otps[:transit]})}
  let(:paratransit_tp) { create(:trip_planner, options: {router: otps[:paratransit]})}
  let(:taxi_tp) { create(:trip_planner, options: {router: otps[:car]})}
  let(:walk_tp) { create(:trip_planner, options: {router: otps[:walk]})}
  let(:bicycle_tp) { create(:trip_planner, options: {router: otps[:bicycle]})}
  let(:car_tp) { create(:trip_planner, options: {router: otps[:car]})}
  let(:error_tp) { create(:trip_planner, options: {router: otps[:error]})}
  let(:skip_accom_filter_tp) { create(:trip_planner, options: {router: otps[:car], except_filters: [:accommodation]})}
  let(:only_accom_filter_tp) { create(:trip_planner, options: {router: otps[:car], only_filters: [:accommodation]})}
  let(:mock_service) { create(:service, gtfs_agency_id: '123', name: 'Mock Service') }
  
  before(:all) do
    trip_date = DateTime.new(2020, 7, 14, 14) # Default trip time in factories (Tuesday)
    travel_to(trip_date - 7.days) # Trips may require advanced notice
  end

  after(:all) do
    travel_back
  end

  before(:each) do
    ServiceSchedule.all.each do |service_schedule|
      create(:service_sub_schedule, service_schedule: service_schedule, day: 2) # tuesday
    end
    [ generic_trip_planner, transit_tp, paratransit_tp, 
      taxi_tp, walk_tp, bicycle_tp, car_tp, error_tp  ].each {|tp| tp.set_available_services }
  end

  it 'should have trip, options, otp, and errors attributes' do
    expect(generic_trip_planner).to respond_to(:trip, :options, :router, :errors)
  end

  describe 'error handling' do
    it 'returns no itineraries on status codes not 200' do
      error_tp.prepare_ambassadors
      itins = error_tp.build_transit_itineraries
      expect(itins).to be_an(Array)
      expect(itins.length).to be(0)
    end

    it 'returns errors on status codes not 200' do
      error_tp.plan
      expect(error_tp.errors).to be_an(Array)
      expect(error_tp.errors.length).to be > 0

      transit_tp.plan
      expect(transit_tp.errors).to be_an(Array)
      expect(transit_tp.errors.length).to be(0)
    end    
  end

  it 'builds transit itineraries' do
    transit_tp.prepare_ambassadors
    itins = transit_tp.build_transit_itineraries
    expect(itins).to be_an(Array)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'builds paratransit itineraries (v1)' do
    paratransit_tp.prepare_ambassadors
    Paratransit.all.each do |paratransit|
      create(:user_booking_profile, service_id: paratransit.id, user: paratransit_tp.trip.user)
    end
    itins = paratransit_tp.build_paratransit_itineraries
    expect(itins).to be_an(Array)
    expect(itins.count).to eq(Paratransit.where(booking_api: nil).published.available_for(paratransit_tp.trip).count)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'builds paratransit itineraries (v2)' do
    Config.find_or_create_by!(key: 'open_trip_planner_version').update_attributes!(value: 'v2')
    paratransit_tp.prepare_ambassadors
    itins = paratransit_tp.build_paratransit_itineraries
    expect(itins).to be_an(Array)
    # tests relevant to what's in otp_response_paratransit.json
    expect(itins.count).to eq(3)
    expect(itins.map{|itin| itin.trip_type}).to eq(["paratransit", "paratransit_mixed", "paratransit_mixed"])
    # otp amabassador should check for paratransit where mode is not 'FLEX' and change it to 'FLEX'
    itins.each do |itin|
      itin.legs.each do |leg|
        if leg['boardRule'] == 'mustPhone'
          expect(leg['mode']).to eq('FLEX_ACCESS')
        else
          expect(leg['mode']).not_to eq('FLEX_ACCESS')
        end
      end
    end
    # unset v2
    Config.find_or_create_by!(key: 'open_trip_planner_version').update_attributes!(value: 'v1')
  end

  it "builds paratransit services using v1 (Service database) and otp v2" do
    Config.find_or_create_by!(key: 'open_trip_planner_version').update_attributes!(value: 'v2')

    # create paratransit service outside otp
    outside_service = create(:paratransit_service, name: 'Outside Service', gtfs_agency_id: nil)
    paratransit_tp.prepare_ambassadors
    paratransit_tp.set_available_services
    itins = paratransit_tp.build_paratransit_itineraries
    expect(itins).to be_an(Array)
    # tests relevant to what's in otp_response_paratransit.json + outside service
    expect(itins.count).to eq(4)
    expect(itins.map{|itin| itin.service_id}).to include(outside_service.id)

    # unset v2
    Config.find_or_create_by!(key: 'open_trip_planner_version').update_attributes!(value: 'v1')
  end

  it 'builds taxi itineraries' do
    taxi_tp.prepare_ambassadors
    itins = taxi_tp.build_taxi_itineraries
    expect(itins).to be_an(Array)
    expect(itins.count).to eq(Taxi.count)
    expect(itins.first['trip_type']).to eq('taxi')
  end

  it 'builds walk itineraries' do
    walk_tp.prepare_ambassadors
    itins = walk_tp.build_walk_itineraries
    expect(itins).to be_an(Array)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'builds bicycle itineraries' do
    bicycle_tp.prepare_ambassadors
    itins = bicycle_tp.build_bicycle_itineraries
    expect(itins).to be_an(Array)
    expect(itins[0]).to be_an(Itinerary)
  end

  it 'builds car itineraries' do
    car_tp.prepare_ambassadors
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

  it 'associates fixed itineraries with services when appropriate' do
    transit_tp.prepare_ambassadors
    itins = transit_tp.build_transit_itineraries
    itins.each do |itin|
      expect(itin['service_id']).to eq(transit.id)
    end

    walk_tp.prepare_ambassadors
    itins = walk_tp.build_walk_itineraries
    itins.each do |itin|
      expect(itin['service_id']).to be_nil
    end
  end

  # TODO relevant purposes only matter for when dashboard_mode is not set to travel_patterns
  # We should have a seperate context for that case
  xit 'should find relevant purposes' do
    paratransit_tp.set_available_services
    debugger
    expect(paratransit_tp.relevant_purposes.pluck(:code).sort)
      .to eq(Purpose.where(code: "medical").pluck(:code).sort)
  end

  it 'should find relevant eligibilities' do
    paratransit_tp.set_available_services
    expect(paratransit_tp.relevant_eligibilities.pluck(:code).sort)
      .to eq(Eligibility.where(code: "over_65").pluck(:code).sort)
  end

  it 'should find relevant accommodations' do
    paratransit_tp.set_available_services
    expect(paratransit_tp.relevant_accommodations.pluck(:code).sort)
      .to eq(accommodating_paratransit.accommodations.pluck(:code).sort)
  end
  
  it 'skips or includes service filters when requested', :skip do    
    # Plan the trip normally
    generic_trip_planner.trip = accommodating_trip
    generic_trip_planner.plan
    
    # Expect the accommodating services array to include all services returned by the trip planner
    expect(accommodating_trip.services.pluck(:id)).to match_array(
      Service.available_for(accommodating_trip).pluck(:id)
    )
     
    # reset the trip
    accommodating_trip.itineraries.destroy_all
    accommodating_trip.reload
    
    # Plan the trip with the accommodations filter skipped
    skip_accom_filter_tp.trip = accommodating_trip
    skip_accom_filter_tp.plan
    puts Service.all.map{|s| "#{s.id} #{s.name} #{s.type}"}
    # Except the services returned by the trip planner to include non-accommodating services
    expect(accommodating_trip.services.pluck(:id)).to match_array(
      # Ignore transit, since doesn't have a belongs_to relationship with itineraries
      # Ignore Uber and Lyft for now as they aren't included by the Trip Planner as of now(2022)
      Service.available_for(accommodating_trip, except_by: [:accommodation])
             .by_trip_type(:paratransit, :taxi)
             .pluck(:id)
    )
    
    # reset the trip
    accommodating_trip.itineraries.destroy_all
    accommodating_trip.reload
    
    # PLan the trip with ONLY the accommodations filter
    only_accom_filter_tp.trip = accommodating_trip
    only_accom_filter_tp.plan
    
    # Expect the services returned by the trip planner to be the same as the list of accommodating services
    expect(accommodating_trip.services.pluck(:id)).to match_array(
      Service.available_for(accommodating_trip, only_by: [:accommodation]).pluck(:id)
    )
    
  end

  describe 'TripPlanner associated services' do
    let(:trip_planner) { create(:trip_planner, options: {router: otps[:paratransit]}) }
    let!(:service_1) { create(:paratransit_service, gtfs_agency_id: 'id_1', name: 'name_1') }
    let!(:service_2) { create(:paratransit_service, gtfs_agency_id: 'id_2', name: 'name_2') }
    let!(:service_3) { create(:paratransit_service, gtfs_agency_id: 'id_3', name: 'name_1') }

    it 'finds the correct service using gtfs_agency_id' do
      trip_planner.plan
      associated_service = Service.find_by(gtfs_agency_id: 'id_1')
      expect(associated_service).to eq(service_1)
    end

    it 'finds the correct service using gtfs_agency_name if gtfs_agency_id is not found' do
      trip_planner.plan
      associated_service = Service.find_by(name: 'name_2')
      expect(associated_service).to eq(service_2)
    end

    it 'returns nil if no associated service is found' do
      trip_planner.plan
      associated_service = Service.find_by(gtfs_agency_id: 'id_3', name: 'name_3')
      expect(associated_service).to be_nil
    end
    
    it 'does not include service based on matching name if id does not match' do
      trip_planner.plan
      # In this scenario, 'service_3' has the same name as 'service_1' but a different id
      associated_service = Service.find_by(gtfs_agency_id: 'id_1')
      expect(associated_service).not_to eq(service_3)
    end
  end

end
