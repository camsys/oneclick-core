require 'rails_helper'

RSpec.describe Api::V1::PlacesController, type: :controller do
  let!(:landmark) { create :landmark }
  let(:request_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }
  let!(:trip) { create :trip }
  let(:user) { trip.user }

  it 'searches for cambridge systematics landmark' do

    get :search, params: {search_string: "%Cambridge%"}, format: :json

    json = JSON.parse(response.body)

    # test for the 200 status-code
    expect(response).to be_success

    # There is only one search that matches
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['record_count']).to eq(1)
  end

  it 'searches for a landmark that does not exist' do
    get :search, params: {search_string: "%blah%"}, format: :json

    json = JSON.parse(response.body)

    # test for the 200 status-code
    expect(response).to be_success

    # There should be ZERO results
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['record_count']).to eq(0)
  end

  it 'searches by address' do

    create :fenway_park
    get :search, params: {search_string: "4 Yawkey Way"}, format: :json

    json = JSON.parse(response.body)

    # test for the 200 status-code
    expect(response).to be_success

    # There is only one search that matches
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['record_count']).to eq(1)
  end

  it "returns user's recent places, limited by count" do
    request.headers.merge!(request_headers) # Send user email and token headers

    # Make a call without a count parameter, match it to user's places
    get :recent, format: :json
    response_body = JSON.parse(response.body)
    expect(response_body["places"].count).to eq(user.recent_waypoints.count)
    expect(response_body["places"].pluck("id")).to eq(user.recent_waypoints.pluck(:id))

    # Now limit by count = 1
    get :recent, params: {count: 1}, format: :json
    response_body = JSON.parse(response.body)
    expect(response_body["places"].count).to eq(1)

  end

end
