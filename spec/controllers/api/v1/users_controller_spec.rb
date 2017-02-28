require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do

  let!(:traveler) { FactoryGirl.create :user }

  it 'returns the first and last name of a user profile' do
    sign_in traveler

    request.headers['X-User-Token'] = traveler.authentication_token
    request.headers['X-User-Email'] = "test_user@camsys.com"
    get :profile, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Check on a specific translation
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["first_name"]).to eq("Bob")
    expect(parsed_response["last_name"]).to eq("Bobson")
  end

end