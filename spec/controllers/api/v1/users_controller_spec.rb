require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do

  let!(:traveler) { FactoryGirl.create :user }
  let!(:english_traveler) { FactoryGirl.create(:english_speaker, :eligible, :not_a_veteran, :needs_accommodation) }

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

  it 'returns the preferred trip types' do
    sign_in english_traveler

    request.headers['X-User-Token'] = english_traveler.authentication_token
    request.headers['X-User-Email'] = english_traveler.email
    get :profile, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Check on a specific translation
    parsed_response = JSON.parse(response.body)
    # There should be 2 preferred modes
    expect(parsed_response["preferred_modes"].count).to eq(2)
    # transit should be preferred
    expect('transit'.in? parsed_response["preferred_modes"]).to eq(true)
    # unicycle should be preferred
    expect('unicycle'.in? parsed_response["preferred_modes"]).to eq(true)
    # it should not include car
    expect('car'.in? parsed_response["preferred_modes"]).to eq(false)
  end

  it 'returns the users eligibilities' do
    sign_in english_traveler

    request.headers['X-User-Token'] = english_traveler.authentication_token
    request.headers['X-User-Email'] = english_traveler.email
    get :profile, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Should be 1 Eligibility Question Answered
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["characteristics"].count).to eq(2)

    # It should be over_65 and the value should be true
    expect(parsed_response["characteristics"].first['code']).to eq('over_65')
    expect(parsed_response["characteristics"].first['value']).to eq(true)
    expect(parsed_response["characteristics"].first['name']).to eq('missing key over_65_name') # Just make sure we are making the call to get a name
    expect(parsed_response["characteristics"].first['note']).to eq('missing key over_65_note') # Just make sure we are making the call to get a note

    # It should NOT be a veteran
    expect(parsed_response["characteristics"].last['code']).to eq('veteran')
    expect(parsed_response["characteristics"].last['value']).to eq(false)
  end 

  it 'returns the users accommodations' do
    sign_in english_traveler

    request.headers['X-User-Token'] = english_traveler.authentication_token
    request.headers['X-User-Email'] = english_traveler.email
    get :profile, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Should be 1 Eligibility Question Answered
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["characteristics"].count).to eq(2)

    # He needs space for a wheelchair
    expect(parsed_response["accommodations"].first['code']).to eq('wheelchair')

    # gotta have that Jacuzzi
    expect(parsed_response["accommodations"].last['code']).to eq('jacuzzi')
    expect(parsed_response["accommodations"].last['name']).to eq('missing key jacuzzi_name') # Just make sure we are making the call to get a name
    expect(parsed_response["accommodations"].last['note']).to eq('missing key jacuzzi_note') # Just make sure we are making the call to get a note
  end 

end
