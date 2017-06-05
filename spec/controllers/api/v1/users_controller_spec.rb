require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do

  let(:traveler) { FactoryGirl.create :user }
  let(:english_traveler) { FactoryGirl.create(:english_speaker) }
  let!(:over_65) { FactoryGirl.create :eligibility }
  let!(:veteran) { FactoryGirl.create :veteran } 
  let!(:jacuzzi) { FactoryGirl.create :jacuzzi }
  let!(:wheelchair) { FactoryGirl.create :wheelchair }

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
    # Set the users eligibilities
    english_traveler.update_eligibilities({over_65: true, veteran: false})

    request.headers['X-User-Token'] = english_traveler.authentication_token
    request.headers['X-User-Email'] = english_traveler.email
    get :profile, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Should be 2 Eligibility Questions Answered
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["characteristics"].count).to eq(2)

    # It should be over_65 and the value should be true
    expect(parsed_response["characteristics"].first['code']).to eq('over_65')
    expect(parsed_response["characteristics"].first['value']).to eq(true)
    expect(parsed_response["characteristics"].first['name']).to eq('missing key eligibility_over_65_name') # Just make sure we are making the call to get a name
    expect(parsed_response["characteristics"].first['note']).to eq('missing key eligibility_over_65_note') # Just make sure we are making the call to get a note
    expect(parsed_response["characteristics"].first['question']).to eq('missing key eligibility_over_65_question') # Just make sure we are making the call to get a question

    # It should NOT be a veteran
    expect(parsed_response["characteristics"].last['code']).to eq('veteran')
    expect(parsed_response["characteristics"].last['value']).to eq(false)
  end 

  it 'returns the users accommodations' do
    sign_in english_traveler

    # Set the users accommodations
    english_traveler.update_accommodations({wheelchair: true, jacuzzi: true})

    request.headers['X-User-Token'] = english_traveler.authentication_token
    request.headers['X-User-Email'] = english_traveler.email
    get :profile, format: :json

    # test for the 200 status-code
    expect(response).to be_success

    # Should be 1 Eligibility Question Answered
    parsed_response = JSON.parse(response.body)
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

    params = {attributes: {first_name: "Jorge", last_name: "Birdell", email: "gpburdell@email.net", lang: "en", preferred_modes: ['clown_car'] }}

    post :update, params: params
    
    # Confirm the Response was a Success 
    expect(response).to be_success

    # Refresh the User's Attributes from the DB
    traveler.reload 

    # Confirm that all the attributes were updated
    expect(traveler.first_name).to eq("Jorge")
    expect(traveler.last_name).to eq("Birdell")
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
    params = {characteristics: {over_65: true, veteran: true}}
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
    params = {characteristics: {veteran: false}}
    post :update, params: params
    # Confirm the Response was a Success 
    expect(response).to be_success
    # Refresh the User's Attributes from the DB
    traveler.reload 
    # Confirm that all the attributes were updated
    expect(traveler.user_eligibilities.find_by(eligibility: veteran).value).to eq(false)
    expect(traveler.user_eligibilities.find_by(eligibility: over_65).value).to eq(true)
  end

  it 'creates a new guest user command' do
    user_count = User.count
    get :get_guest_token
    expect(response).to be_success
    expect(User.count).to eq(user_count + 1)
    parsed_response = JSON.parse(response.body)
    expect(parsed_response["email"]).to be
    expect(parsed_response["authentication_token"]).to be
  end

end
