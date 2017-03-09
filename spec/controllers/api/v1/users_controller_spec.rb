require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do

  let!(:traveler) { FactoryGirl.create :user }
  let!(:english_traveler) { FactoryGirl.create :english_speaker }

  it 'returns the first and last name of a user profile' do
    sign_in traveler

    request.headers['X-User-Token'] = traveler.authentication_token
    request.headers['X-User-Email'] = traveler.email
    get :profile, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Check on a specific translation
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["first_name"]).to eq("Bob")
    expect(parsed_response["last_name"]).to eq("Bobson")
  end

  it 'returns the preferred locale' do
    sign_in english_traveler

    request.headers['X-User-Token'] = english_traveler.authentication_token
    request.headers['X-User-Email'] = english_traveler.email
    get :profile, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Check on a specific translation
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["lang"]).to eq("en")
  end

end
