require 'rails_helper'

RSpec.describe Api::V2::TripsController, type: :controller do
  let!(:user) { create(:user) }  
  let!(:user_agency) { create(:transportation_agency, name: "User Agency") }
  let(:user_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }
  let!(:weekly_pattern) { create(:travel_pattern, :with_weekly_pattern_schedule, agency: user_agency) }
  let(:weekly_date) { (Date.current + 2.days).strftime('%Y-%m-%d') }

  # Create necessary configs, purposes, and characteristics
  before(:each) do
    create(:traveler_transit_agency, transportation_agency: user_agency, user: user)

    create(:otp_config)
    create(:tff_config)
    create(:uber_token)
    create(:lyft_client_token)
    3.times { |i| create(:purpose)}
    create(:travel_pattern_purpose, travel_pattern: weekly_pattern, purpose: Purpose.first)
  end

  let(:origin) { 
    geom = weekly_pattern.origin_zone.region.geom
    {
      lat: geom.centroid.y,
      lng: geom.centroid.x
    }
  }
  let(:destination) { 
    geom = weekly_pattern.destination_zone.region.geom
    {
      lat: geom.centroid.y,
      lng: geom.centroid.x
    }
  }
  let(:plan_call_params) { 
    {
      trip: {
        origin_attributes: origin,
        destination_attributes: destination,
        arrive_by: (rand(2) == 1),
        trip_time: (Date.current + 2.days + 12.hours).iso8601,
        purpose: Purpose.first.name
      },
      trip_types: [:paratransit, :walk],
      only_filters: [:schedule, :eligibility, :purpose],
      except_filters: [:purpose],
      user_profile: {
        attributes: { first_name: user.first_name + "_new" }
      }
    } 
  }
  
  ### PLANNING ###

  describe "planning" do
    
    # Stub trip planners to not do anything in response to a plan call
    before(:each) do
      allow_any_instance_of(TripPlanner).to receive(:plan).and_return(true)
      allow_any_instance_of(TripPlanner).to receive(:relevant_purposes).and_return(Purpose.all)      
      allow_any_instance_of(TripPlanner).to receive(:relevant_accommodations).and_return(Accommodation.all)      
      allow_any_instance_of(TripPlanner).to receive(:relevant_eligibilities).and_return(Eligibility.all)      
    end
    
    # Test for trip params: origin, destination, arrive_by, trip_time, purpose,
    # user.
    it "faithfully creates a trip based on passed params" do
      request.headers.merge!(user_headers)
      
      post :create, params: plan_call_params
      expect(response).to be_success
      
      requested_trip = plan_call_params[:trip]
      created_trip = assigns(:trip)
      
      expect(created_trip.origin.lat.to_f).to eq(requested_trip[:origin_attributes][:lat].round(6))
      expect(created_trip.origin.lng.to_f).to eq(requested_trip[:origin_attributes][:lng].round(6))
      expect(created_trip.destination.lat.to_f).to eq(requested_trip[:destination_attributes][:lat].round(6))
      expect(created_trip.destination.lng.to_f).to eq(requested_trip[:destination_attributes][:lng].round(6))
      expect(created_trip.arrive_by).to eq(requested_trip[:arrive_by])
      expect(created_trip.trip_time).to eq(requested_trip[:trip_time])
      expect(created_trip.purpose).to eq(Purpose.find_by(code: requested_trip[:purpose]))
      expect(created_trip.user).to eq(user)
    end
    
    # Test for options: trip_type, only_filters, except_filters
    it "passes options along to trip planner" do
      request.headers.merge!(user_headers)
      
      post :create, params: plan_call_params

      tp = assigns(:trip_planner)
      
      expect(tp.trip_types).to eq(plan_call_params[:trip_types])
      expect(tp.only_filters).to eq(plan_call_params[:only_filters])
      expect(tp.except_filters).to eq(plan_call_params[:except_filters])
    end
    
    it "updates user profile" do
      request.headers.merge!(user_headers)
      
      post :create, params: plan_call_params
      
      user.reload
      expect(user.first_name).to eq(plan_call_params[:user_profile][:attributes][:first_name])
    end
    
    it "returns trip with relevant accommodations, eligibilities, and purposes" do
      request.headers.merge!(user_headers)
      
      post :create, params: plan_call_params
      
      created_trip = assigns(:trip)
      
      expect(created_trip.relevant_purposes).to eq(Purpose.all)
      expect(created_trip.relevant_accommodations).to eq(Accommodation.all)
      expect(created_trip.relevant_eligibilities).to eq(Eligibility.all)
    end
    
    # Spot check if the ApiRequestLogger is working properly
    it "logs api requests" do
      request_logs_count = RequestLog.count
      
      request.headers.merge!(user_headers)
      post :create, params: plan_call_params
      
      expect(RequestLog.count).to eq(request_logs_count + 1)
      
      log = RequestLog.last
      
      expect(log.status_code).to eq('200')
      expect(log.controller).to eq("Api::V2::TripsController")
      expect(log.action).to eq("create")
      expect(log.auth_email).to eq(user.email)
      expect(log.params).to be
    end
    
  end
  
  
  ### OTHER CALLS ###
  
  it "gets a trip by ID if user headers are passed" do
    trip = create(:trip, user: user)
    
    request.headers.merge!(user_headers)
    
    get :show, params: { id: trip.id }
    
    response_body = JSON.parse(response.body)
    
    expect(response).to be_success    
    expect(response_body["data"]["trip"]).to be
  end

end
