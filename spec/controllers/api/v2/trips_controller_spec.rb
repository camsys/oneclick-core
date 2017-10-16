require 'rails_helper'

RSpec.describe Api::V2::TripsController, type: :controller do
  
  # Create necessary configs, purposes, and characteristics
  before(:each) do 
    create(:otp_config)
    create(:tff_config)
    create(:uber_token)
    3.times { |i| create(:purpose, code: "purpose_#{i}")}
  end
  
  let!(:user) { create(:user) }  
  let(:user_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }
  
  
  let(:plan_call_params) { 
    {
      trip: { # create a trip with random attributes
        origin_attributes: { lat: 28 + rand(10)/10.0, lng: -81 - rand(10)/10.0 },
        destination_attributes: { lat: 28 + rand(10)/10.0, lng: -81 - rand(10)/10.0 },
        arrive_by: (rand(2) == 1),
        trip_time: (DateTime.now + rand(30).days + rand(24).hours + rand(60).minutes).iso8601,
        purpose: Purpose.first.code.to_s
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
      
      expect(created_trip.origin.lat.to_f).to eq(requested_trip[:origin_attributes][:lat])
      expect(created_trip.origin.lng.to_f).to eq(requested_trip[:origin_attributes][:lng])
      expect(created_trip.destination.lat.to_f).to eq(requested_trip[:destination_attributes][:lat])
      expect(created_trip.destination.lng.to_f).to eq(requested_trip[:destination_attributes][:lng])
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
    
  end

end
