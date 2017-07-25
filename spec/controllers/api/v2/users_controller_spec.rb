require 'rails_helper'

RSpec.describe Api::V2::UsersController, type: :controller do

  let(:traveler) { create :user }
  let(:english_traveler) { create(:english_speaker) }
  let!(:over_65) { create :eligibility }
  let!(:veteran) { create :veteran } 
  let!(:jacuzzi) { create :jacuzzi }
  let!(:wheelchair) { create :wheelchair }

  it 'returns the first and last name of a user profile' do
    first_name = traveler.first_name
    last_name = traveler.last_name

    sign_in traveler

    request.headers['X-User-Token'] = traveler.authentication_token
    request.headers['X-User-Email'] = traveler.email
    get :show, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Check on a specific translation
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["data"]["user"]["first_name"]).to eq(first_name)
    expect(parsed_response["data"]["user"]["last_name"]).to eq(last_name)

  end

  it 'returns the preferred locale' do
    sign_in english_traveler

    request.headers['X-User-Token'] = english_traveler.authentication_token
    request.headers['X-User-Email'] = english_traveler.email
    get :show, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Check on a specific translation
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["data"]["user"]["preferred_locale"]).to eq("en")
  end

  it 'returns the preferred trip types' do
    sign_in english_traveler

    request.headers['X-User-Token'] = english_traveler.authentication_token
    request.headers['X-User-Email'] = english_traveler.email
    get :show, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    parsed_response = JSON.parse(response.body)["data"]["user"]
    expect('transit'.in? parsed_response["preferred_trip_types"]).to eq(true)
    expect('unicycle'.in? parsed_response["preferred_trip_types"]).to eq(true)
    expect('car'.in? parsed_response["preferred_trip_types"]).to eq(false)
  end

  it 'returns the users eligibilities' do
    sign_in english_traveler
    # Set the users eligibilities
    english_traveler.update_eligibilities({over_65: true, veteran: false})

    request.headers['X-User-Token'] = english_traveler.authentication_token
    request.headers['X-User-Email'] = english_traveler.email
    get :show, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Should be 2 Eligibility Questions Answered
    parsed_response = JSON.parse(response.body)["data"]["user"]
    expect(parsed_response["eligibilities"].count).to eq(2)

    # It should be over_65 and the value should be true
    expect(parsed_response["eligibilities"].first['code']).to eq('over_65')
    expect(parsed_response["eligibilities"].first['value']).to eq(true)
    expect(parsed_response["eligibilities"].first['name']).to eq('missing key eligibility_over_65_name') # Just make sure we are making the call to get a name
    expect(parsed_response["eligibilities"].first['note']).to eq('missing key eligibility_over_65_note') # Just make sure we are making the call to get a note
    expect(parsed_response["eligibilities"].first['question']).to eq('missing key eligibility_over_65_question') # Just make sure we are making the call to get a question

    # It should NOT be a veteran
    expect(parsed_response["eligibilities"].last['code']).to eq('veteran')
    expect(parsed_response["eligibilities"].last['value']).to eq(false)
  end 

  it 'returns the users accommodations' do
    sign_in english_traveler

    # Set the users accommodations
    english_traveler.update_accommodations({wheelchair: true, jacuzzi: true})

    request.headers['X-User-Token'] = english_traveler.authentication_token
    request.headers['X-User-Email'] = english_traveler.email
    get :show, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Should be 1 Eligibility Question Answered
    parsed_response = JSON.parse(response.body)["data"]["user"]
    expect(parsed_response["accommodations"].count).to eq(2)

    # The entries should be for wheelchair and jacuzzi, pull those out and confirm that
    accommodations = parsed_response["accommodations"]
    wheelchair_entry = accommodations.find { |i| i['code'] == 'wheelchair' }
    jacuzzi_entry = accommodations.find { |i| i['code'] == 'jacuzzi' }
    
    # He needs space for a wheelchair
    expect(wheelchair_entry['code']).to eq('wheelchair')

    # gotta have that Jacuzzi
    expect(jacuzzi_entry['code']).to eq('jacuzzi')
    expect(jacuzzi_entry['name']).to eq('missing key accommodation_jacuzzi_name') # Just make sure we are making the call to get a name
    expect(jacuzzi_entry['note']).to eq('missing key accommodation_jacuzzi_note') # Just make sure we are making the call to get a note
    expect(jacuzzi_entry['question']).to eq('missing key accommodation_jacuzzi_question') # Just make sure we are making the call to get a question
  end 

  it 'updates basic attributes for a user' do
    sign_in traveler
    request.headers['X-User-Token'] = traveler.authentication_token
    request.headers['X-User-Email'] = traveler.email

    params = {attributes: {first_name: "Jorge", last_name: "Burdell", email: "gpburdell@email.net", preferred_locale: "en"}, preferred_trip_types: ['clown_car']}

    put :update, params: params
    
    # Confirm the Response was a Success 
    expect(response).to be_success

    # Refresh the User's Attributes from the DB
    traveler.reload 

    # Confirm that all the attributes were updated
    expect(traveler.first_name).to eq("Jorge")
    expect(traveler.last_name).to eq("Burdell")
    expect(traveler.email).to eq("gpburdell@email.net")
    expect(traveler.preferred_locale).to eq(Locale.find_by(name:"en"))
    expect(traveler.preferred_trip_types).to eq(['clown_car'])

  end

  it 'adds accommodations for a user' do
    sign_in traveler
    request.headers['X-User-Token'] = traveler.authentication_token
    request.headers['X-User-Email'] = traveler.email

    params = {accommodations: {wheelchair: true, jacuzzi: true}}
    post :update, params: params
    # Confirm the Response was a Success 
    expect(response).to be_success
    # Refresh the User's Attributes from the DB
    traveler.reload 
    # Confirm that all the attributes were updated
    expect(traveler.accommodations.count).to eq(2)
  end

  it 'will remove accommodations for a user' do
    sign_in traveler
    request.headers['X-User-Token'] = traveler.authentication_token
    request.headers['X-User-Email'] = traveler.email

    # First Set 2 accommodations to be needed
    params = {accommodations: {wheelchair: true, jacuzzi: true}}
    post :update, params: params
    # Confirm the Response was a Success 
    expect(response).to be_success
    # Refresh the User's Attributes from the DB
    traveler.reload 
    # Confirm that all the attributes were updated
    expect(traveler.accommodations.count).to eq(2)

    # Now remove the need for a wheelchair
    params = {accommodations: {wheelchair: false}}
    post :update, params: params
    # Confirm the Response was a Success 
    expect(response).to be_success
    # Refresh the User's Attributes from the DB
    traveler.reload 
    # Confirm that all the attributes were updated
    expect(traveler.accommodations.count).to eq(1)
    expect(traveler.accommodations.first.code).to eq('jacuzzi')
  end

  it 'answers eligibility questions' do
    sign_in traveler
    request.headers['X-User-Token'] = traveler.authentication_token
    request.headers['X-User-Email'] = traveler.email

    # First Set 2 Characteristics to true
    params = {eligibilities: {over_65: true, veteran: true}}
    post :update, params: params
    # Confirm the Response was a Success 
    expect(response).to be_success
    # Refresh the User's Attributes from the DB
    traveler.reload 
    # Confirm that all the attributes were updated
    expect(traveler.user_eligibilities.count).to eq(2)
    expect(traveler.user_eligibilities.find_by(eligibility: veteran).value).to eq(true)
    expect(traveler.user_eligibilities.find_by(eligibility: over_65).value).to eq(true)

    # Now remove the need for a wheelchair
    params = {eligibilities: {veteran: false}}
    post :update, params: params
    # Confirm the Response was a Success 
    expect(response).to be_success
    # Refresh the User's Attributes from the DB
    traveler.reload 
    # Confirm that all the attributes were updated
    expect(traveler.user_eligibilities.find_by(eligibility: veteran).value).to eq(false)
    expect(traveler.user_eligibilities.find_by(eligibility: over_65).value).to eq(true)
  end


end
