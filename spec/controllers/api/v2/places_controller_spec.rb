require 'rails_helper'

RSpec.describe Api::V2::PlacesController, type: :controller do
  let!(:landmark) { create :landmark }
  let(:cambridge_city_hall) { create :cambridge_city_hall }
  let(:stomping_ground) { create :stomping_ground }
  let!(:user) { create :user }
  let(:request_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }

  it 'searches for cambridge systematics landmark' do
    get :index, params: {name: "Cambridge"}, format: :json
    json = JSON.parse(response.body)
    # test for the 200 status-code
    expect(response).to be_success
    # There is only one search that matches
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['data']['places'].count).to eq(1)
  end

  it 'searches for a landmark that does not exist' do
    get :index, params: {name: "blah"}, format: :json
    json = JSON.parse(response.body)
    # test for the 200 status-code
    expect(response).to be_success
    # There should be ZERO results
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['data']['places'].count).to eq(0)
  end

  it "returns a stomping ground" do
    user.stomping_grounds << stomping_ground
    request.headers.merge!(request_headers) # Send user email and token headers
    # Make a call without a count parameter, match it to user's places
    get :index, params: {name: "work"}, format: :json
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['data']['places'].count).to eq(1)
  end

  it "returns a stomping ground and matching landmarks" do
    user.stomping_grounds << stomping_ground
    user.stomping_grounds << cambridge_city_hall
    request.headers.merge!(request_headers) # Send user email and token headers
    # Make a call without a count parameter, match it to user's places
    get :index, params: {name: "cambridge"}, format: :json
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['data']['places'].count).to eq(2)
  end
  
  it "returns user's recent places" do
    3.times do
      user.trips << create(:trip)
    end
    
    query_str = user.origins.first.name.split(' ').first

    request.headers.merge!(request_headers) # Send user email and token headers
    get :index, params: {name: query_str}, format: :json
    parsed_response = JSON.parse(response.body)
    
    # Should find one unique place that matches the given name
    expect(parsed_response['data']['places'].count).to eq(1)
    recent_place = user.origins.last
    returned_place = parsed_response['data']['places'].first

    expect(returned_place["geometry"]["location"]["lat"].to_f).to eq(recent_place.lat.to_f)
    expect(returned_place["geometry"]["location"]["lng"].to_f).to eq(recent_place.lng.to_f)
    expect(returned_place["name"]).to eq(recent_place.name)
  end

end
