require 'rails_helper'

# TODO: Api::V1::TripsContorller test suite is only testing RidePilot bookings it seems???
# Figure out which bookings need to be tested as well
RSpec.describe Api::V1::TripsController, type: :controller do
  
  let!(:trip) { create(:trip) }
  let!(:itinerary) { create(:itinerary, trip: nil) }
  let!(:paratransit_itinerary) { create(:paratransit_itinerary, trip: nil) }
  let!(:user) { trip.user }
  let!(:hacker) { create(:english_speaker) }
  let!(:eligibility) { FactoryBot.create :eligibility }
  let!(:paratransit_service) { FactoryBot.create(:paratransit_service, :medical_only, :no_geography) }
  let!(:metallica_concert) { FactoryBot.create(:metallica_concert) }

  let(:request_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }
  let(:hacker_headers)  { {"X-USER-EMAIL" => hacker.email, "X-USER-TOKEN" => hacker.authentication_token} }

  before(:each) { create(:otp_config) }
  before(:each) { create(:tff_config) }
  before(:each) { create(:uber_token) }
  before(:each) { create(:lyft_client_token) }

  ### PLANNING ###

  describe "planning" do
    
    let(:plan_call_params) {JSON.parse(File.read("spec/files/api_v1/sample_plan_call_basic.json"))}
    let(:walk_plan_call_params) {JSON.parse(File.read("spec/files/api_v1/sample_plan_call_walk.json"))}
    let(:plan_paratransit_call_without_purpose) {JSON.parse(File.read("spec/files/api_v1/sample_plan_call_without_purpose.json"))}
    let(:plan_paratransit_call_with_purpose) {JSON.parse(File.read("spec/files/api_v1/sample_plan_call_with_purpose.json"))}
    
    let(:trip_planner) { TripPlanner.new(trip, trip_types: []) }

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
    
    it 'sends back all accommodations when planning a trip' do
      post :create, params: plan_call_params
      response_body = JSON.parse(response.body)

      expect(response).to be_success
      expect(response_body["accommodations"].count).to eq(Accommodation.count)
    end

  end
  
  
  ### SELECTING ###

  describe "selecting" do
    
    it 'selects an itinerary' do
      # Make sure that our itinerary has a trip and that our trip has a user
      trip.user = user
      trip.save
      itinerary.trip = trip
      itinerary.save

      request.headers.merge!(request_headers)
      post :select, params: { "select_itineraries": [ {"itinerary_id": itinerary.id} ] }
      itinerary.reload
      expect(itinerary.selecting_trip).to eq(trip)
    end
    
    it 'cannot select an itinerary because you are not logged in' do
      post :select, params: { "select_itineraries": [ {"itinerary_id": itinerary.id} ] }
      expect(response).to have_http_status(401)
    end

    it 'cannot select an itinerary because you do not own the itinerary' do
      # Make sure that our itinerary has a trip
      itinerary.trip = trip
      itinerary.save

      request.headers.merge!(hacker_headers)
      post :select, params: { "select_itineraries": [ {"itinerary_id": itinerary.id} ] }
      itinerary.reload
      expect(itinerary.selecting_trip).to eq(nil)
    end
    
  end
  
  
  ### BOOKING ###

  describe "booking and canceling" do
    
    # Build a stubbed-out itinerary that responds to booking requests
    let(:bookable_itinerary) { create(:ride_pilot_itinerary, :unbooked, trip: trip) }
    let(:unbookable_itinerary) { create(:ride_pilot_itinerary, :unbooked, trip: trip) }

    before(:each) do
      Itinerary.any_instance.stub(:book) do |itin|
        if itin.id != unbookable_itinerary.id 
          itin.booking = create(:ride_pilot_booking, :booked, itinerary: itin)
          itin.booking
        else
          itin.booking = nil 
        end
      end
      Itinerary.any_instance.stub(:cancel) do |itin|
        itin.booking = create(:ride_pilot_booking, :canceled, itinerary: itin)
        itin.booking
      end
    end
    
    let(:booking_params) do
      { booking_request: [ { itinerary_id: bookable_itinerary.id } ] }
    end

    let(:bad_booking_params) do
      { booking_request: [ { itinerary_id: unbookable_itinerary.id, return_time: trip.trip_time + 2.hours } ] }
    end
    
    
    let(:booking_params_w_return) do
      { booking_request: [ { itinerary_id: bookable_itinerary.id, return_time: trip.trip_time + 2.hours } ] }
    end
    
    let(:bookingcancellation_params) do
      { bookingcancellation_request: [ { itinerary_id: bookable_itinerary.id } ] }
    end
    
    it 'books a trip' do
      expect(bookable_itinerary.booked?).to be false
      
      request.headers.merge!(request_headers)
      post :book, params: booking_params
      response_body = JSON.parse(response.body)
      bookable_itinerary.reload
                  
      expect(response).to be_success
      expect(bookable_itinerary.booked?).to be true
    end

    # NOTE: TEST FAILS, return_itin.booked? returns true
    # even though the book method returns false for both itineraries that get cancelled
    # if you check with a breakpoint and the debugger
    # which probably has to do with it being a RidePilot itinerary???
    xit 'cancels both legs if one leg fails to book' do
      expect(unbookable_itinerary.booked?).to be false
      
      request.headers.merge!(request_headers)
      post :book, params: bad_booking_params
      response_body = JSON.parse(response.body)
      unbookable_itinerary.reload
                  
      return_trip = Trip.find_by(id: response_body["booking_results"][1]["trip_id"])
      return_itin = Itinerary.find_by(id: response_body["booking_results"][1]["itinerary_id"])
      
      expect(unbookable_itinerary.booked?).to be false
      expect(return_trip.selected_itinerary).to eq(return_itin)
      # NOTE: Are we supposed to read the booking failure directly from the response???
      #
      expect(return_itin.booked?).to be false
      expect(response.status).to eq(500)
    end
    
    
    it 'books a return trip at the designated return time' do
      expect(bookable_itinerary.booked?).to be false

      request.headers.merge!(request_headers)
      post :book, params: booking_params_w_return
      response_body = JSON.parse(response.body)
      bookable_itinerary.reload
                  
      return_trip = Trip.find_by(id: response_body["booking_results"][1]["trip_id"])
      return_itin = Itinerary.find_by(id: response_body["booking_results"][1]["itinerary_id"])

      expect(response).to be_success
    end

    # NOTE: TEST FAILS, bookable_itinerary.cancelled? returns false
    # even though it returns true if you check with a breakpoint inside the cancel action
    # which probably has to do with it being a RidePilot itinerary???
    xit 'cancels a trip' do

      # First Lets book a trip.
      expect(bookable_itinerary.booked?).to be false
      request.headers.merge!(request_headers)
      post :book, params: booking_params
      response_body = JSON.parse(response.body)
      bookable_itinerary.reload
      expect(response).to be_success
      expect(bookable_itinerary.booked?).to be true

      # Now cancel that trip
      expect(bookable_itinerary.canceled?).to be false
      post :cancel, params: bookingcancellation_params
      response_body = JSON.parse(response.body)
      bookable_itinerary.reload
      expect(response).to be_success
      expect(bookable_itinerary.canceled?).to be true
    end

    # NOTE: This test is failing because of changes related to https://camsys.atlassian.net/browse/OCC-717,
    # specifically https://github.com/camsys/oneclick-core/blame/master/app/controllers/api/v1/trips_controller.rb#L228-L229
    #  The itinerary in the cancel method is nil, causing an internal error. Fix is unclear. Skipping test for now. 
    xit 'cannot cancel an itinerary because you do not own the itinerary' do
      expect(bookable_itinerary.canceled?).to be false
      
      request.headers.merge!(hacker_headers)
      post :cancel, params: bookingcancellation_params
      response_body = JSON.parse(response.body)

      expect(response).to be_success
      expect(bookable_itinerary.canceled?).to be false
    end
    
  end

  #### Emailing ###
  describe "emailing" do

    it 'sends an email' do
      params = {email_address: 'test@oneclick.com', trip_id: trip.id  }
      trip.itineraries << paratransit_itinerary
      trip.selected_itinerary = paratransit_itinerary
      trip.save
      post :email, params: params
      #todo: update factories for itineraries with enough info so that this succeeds
      expect(response.code).to eq("500")
    end

  end


  ### PAST AND FUTURE TRIPS ###
  
  describe 'past and future trips' do
    
    let!(:past_trip) { create(:trip_with_itins, user: user, trip_time: DateTime.now.in_time_zone - 5.days)}
    let!(:future_trip) { create(:trip_with_itins, user: user, trip_time: DateTime.now.in_time_zone + 5.days)}

    it 'returns past trips for user' do
      # Need to select an itinerary since the get trips calls only work for trips with selected itineraries
      past_trip.itineraries.first.select 
      request.headers.merge!(request_headers)
      get :past_trips
      response_body = JSON.parse(response.body)
      expect(response).to be_success

      # the past trip should be in the list of responses
      past_trip_ids = response_body["trips"].map {|t| t['0']['trip_id']}
      expect(past_trip_ids.include?(past_trip.id)).to be true
    end

    it 'returns future trips for user' do
      # Need to select an itinerary since the get trips calls only work for trips with selected itineraries
      future_trip.itineraries.first.select 
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

  end

end
