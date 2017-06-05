require 'rails_helper'

RSpec.describe Api::V1::TripsController, type: :controller do

  let(:request_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }
  let(:plan_call_params) {JSON.parse(File.read("spec/files/sample_plan_call_basic.json"))}
  let(:walk_plan_call_params) {JSON.parse(File.read("spec/files/sample_plan_call_walk.json"))}
  let(:plan_paratransit_call_without_purpose) {JSON.parse(File.read("spec/files/sample_plan_call_without_purpose.json"))}
  let(:plan_paratransit_call_with_purpose) {JSON.parse(File.read("spec/files/sample_plan_call_with_purpose.json"))}
  let(:trip) { create(:trip) }
  let(:itinerary) { create(:itinerary)}
  let(:user) { trip.user }
  let(:hacker) { create(:english_speaker) }
  let(:trip_planner) { TripPlanner.new(trip, trip_types: []) }
  let!(:eligibility) { FactoryGirl.create :eligibility }
  let!(:paratransit_service) { FactoryGirl.create(:paratransit_service, :medical_only, :no_geography) }
  let!(:metallica_concert) { FactoryGirl.create(:metallica_concert) }
  let!(:past_trip) { create(:trip, user: user, trip_time: DateTime.now.in_time_zone - 5.days)}
  let!(:future_trip) { create(:trip, user: user, trip_time: DateTime.now.in_time_zone + 5.days)}

  # Stub trip planner methods
  before(:each) do
    allow(trip_planner).to receive(:plan) do
      trip_planner.trip.itineraries << itinerary
    end
    allow(TripPlanner).to receive(:new) { trip_planner }
  end


  it 'creates a trip with a user, origin, destination, trip_time, and arrive_by type' do

    request.headers.merge!(request_headers) # Send user email and token headers
    post :create, params: plan_call_params
    response_body = JSON.parse(response.body)

    trip_request = plan_call_params["itinerary_request"][0]

    expect(response).to be_success
    expect(response_body["user_id"]).to eq(user.id)
    expect(response_body["origin"]).to be
    expect(response_body["destination"]).to be
    expect(response_body["trip_time"].to_datetime).to eq(trip_request["trip_time"].to_datetime)
    expect(response_body["arrive_by"]).to eq(trip_request["departure_type"] == "arrive")
  end


  it 'responds to a walk trip' do
    request.headers.merge!(request_headers) # Send user email and token headers
    post :create, params: walk_plan_call_params
    response_body = JSON.parse(response.body)
    trip_request = plan_call_params["itinerary_request"][0]
    expect(response).to be_success
    expect(response_body["user_id"]).to eq(user.id)
    expect(response_body["origin"]).to be
    expect(response_body["destination"]).to be
    expect(response_body["trip_time"].to_datetime).to eq(trip_request["trip_time"].to_datetime)
    expect(response_body["arrive_by"]).to eq(trip_request["departure_type"] == "arrive")
  end

  # it 'allows creation of multiple trips in one request' do
  #   request.headers.merge!(request_headers) # Send user email and token headers
  #   post :create, params: multi_plan_call_params
  #   response_body = JSON.parse(response.body)
  #
  #   trip_requests_count =  multi_plan_call_params["itinerary_request"].count
  #
  #   expect(response).to be_success
  #   expect(response_body.count).to eq(trip_requests_count)
  # end

  it 'allows creation of trips by guest users' do
    user_count = User.count
    post :create, params: plan_call_params
    response_body = JSON.parse(response.body)

    expect(response).to be_success
    expect(User.count).to eq(user_count+1)
    expect(response_body["new_guest_user"]).to be
  end

  it 'does not create a new guest user when a user is passed' do
    user_count = User.count
    request.headers.merge!(request_headers) # Send user email and token headers
    post :create, params: plan_paratransit_call_without_purpose
    response_body = JSON.parse(response.body)
    expect(response).to be_success
    expect(User.count).to eq(user_count)
    expect(response_body["new_guest_user"]).to be_nil
  end  

  it 'sends back itineraries' do
    # Stub out trip creation because itinerary planning happens in TripPlanner
    allow(Trip).to receive(:create) { [trip] }

    request.headers.merge!(request_headers) # Send user email and token headers
    post :create, params: plan_call_params
    response_body = JSON.parse(response.body)

    expect(response).to be_success
    expect(response_body["itineraries"]).to be
    expect(response_body["itineraries"].count).to be > 0
  end

  it 'cannot select an itinerary because you are not logged in' do
    post :select, params: { "select_itineraries": [ {"itinerary_id": itinerary.id} ] }
    expect(response).to have_http_status(401)
  end

  it 'cannot select an itinerary because you do not own the itinerary' do
    # Make sure that our itinerary has a trip
    itinerary.trip = trip
    itinerary.save

    sign_in hacker
    request.headers['X-User-Token'] = hacker.authentication_token
    request.headers['X-User-Email'] = hacker.email
    post :select, params: { "select_itineraries": [ {"itinerary_id": itinerary.id} ] }
    itinerary.reload
    expect(itinerary.selecting_trip).to eq(nil)
  end

  it 'selects an itinerary' do
    # Make sure that our itinerary has a trip and that our trip has a user
    trip.user = user
    trip.save
    itinerary.trip = trip
    itinerary.save

    sign_in user
    request.headers['X-User-Token'] = user.authentication_token
    request.headers['X-User-Email'] = user.email
    post :select, params: { "select_itineraries": [ {"itinerary_id": itinerary.id} ] }
    itinerary.reload
    expect(itinerary.selecting_trip).to eq(trip)
  end

  it 'cannot cancel an itinerary because you do not own the itinerary' do
    # Make sure that our itinerary has a trip
    trip.user = user
    trip.save
    itinerary.trip = trip
    itinerary.save
    itinerary.select
    itinerary.reload

    expect(itinerary.selecting_trip).to eq(trip)

    sign_in hacker
    request.headers['X-User-Token'] = hacker.authentication_token
    request.headers['X-User-Email'] = hacker.email
    post :cancel, params: { "bookingcancellation_request": [ {"itinerary_id": itinerary.id} ] }
    itinerary.reload
    expect(itinerary.selecting_trip).to eq(trip)
  end

  it 'cancels a trip' do
    # Make sure that our itinerary has a trip
    trip.user = user
    trip.save
    itinerary.trip = trip
    itinerary.save
    itinerary.select
    itinerary.reload

    expect(itinerary.selecting_trip).to eq(trip)

    sign_in user
    request.headers['X-User-Token'] = user.authentication_token
    request.headers['X-User-Email'] = user.email
    post :cancel, params: { "bookingcancellation_request": [ {"itinerary_id": itinerary.id} ] }
    itinerary.reload
    expect(itinerary.selecting_trip).to eq(nil)
  end

  it 'plans a trip without a trip purpose' do
    request.headers.merge!(request_headers) # Send user email and token headers
    post :create, params: plan_paratransit_call_without_purpose
    response_body = JSON.parse(response.body)
    trip_id = response_body['trip_id'].to_i
    expect(response).to be_success
    expect(paratransit_service.available_for?(Trip.find(trip_id))).to eq(true)
  end

  it 'plans a trip with a trip purpose' do
    post :create, params: plan_paratransit_call_with_purpose
    response_body = JSON.parse(response.body)
    trip_id = response_body['trip_id'].to_i
    expect(response).to be_success
    expect(paratransit_service.available_for?(Trip.find(trip_id))).to eq(false)
  end

  it 'returns past trips for user' do
    request.headers.merge!(request_headers)
    get :past_trips

    response_body = JSON.parse(response.body)
    expect(response).to be_success

    # the past trip should be in the list of responses
    past_trip_ids = response_body["trips"].map {|t| t['0']['trip_id']}
    expect(past_trip_ids.include?(past_trip.id)).to be true
  end

  it 'returns future trips for user' do
    request.headers.merge!(request_headers)
    get :future_trips

    response_body = JSON.parse(response.body)
    expect(response).to be_success

    # the past trip should be in the list of responses
    future_trip_ids = response_body["trips"].map {|t| t['0']['trip_id']}
    expect(future_trip_ids.include?(future_trip.id)).to be true
  end

  it 'does not return past or future trips if not authenticated' do
    get :future_trips
    expect(response).to have_http_status(401)
    get :past_trips
    expect(response).to have_http_status(401)
  end

  it 'limits past and future request results to max_results parameter' do
    request.headers.merge!(request_headers)

    get :past_trips, params: {max_results: 0}
    response_body = JSON.parse(response.body)
    expect(response).to be_success
    expect(response_body["trips"].count).to eq(0)

    get :future_trips, params: {max_results: 0}
    response_body = JSON.parse(response.body)
    expect(response).to be_success
    expect(response_body["trips"].count).to eq(0)
  end

  # it 'sends back itineraries for multiple trips' do
  #   # Stub out trip creation because itinerary planning happens in TripPlanner
  #   allow(Trip).to receive(:create) { [trip, trip] }
  #
  #   request.headers.merge!(request_headers) # Send user email and token headers
  #   post :create, params: multi_plan_call_params
  #   response_body = JSON.parse(response.body)
  #
  #   trip_requests_count =  multi_plan_call_params["itinerary_request"].count
  #
  #   expect(response).to be_success
  #   expect(response_body.count).to eq(trip_requests_count)
  #   expect(response_body.map {|t| t["itineraries"]}).to all( be )
  #   expect(response_body.map {|t| t["itineraries"].count}).to all( be > 0 )
  # end

end
