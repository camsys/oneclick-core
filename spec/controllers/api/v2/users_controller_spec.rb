require 'rails_helper'

RSpec.describe Api::V2::UsersController, type: :controller do

  let(:traveler) { create :user }
  let(:english_traveler) { create(:english_speaker) }
  let!(:over_65) { create :eligibility }
  let!(:veteran) { create :veteran } 
  let!(:jacuzzi) { create :jacuzzi }
  let!(:wheelchair) { create :wheelchair }
  
  describe "user sign up" do
    
    it 'signs up a new user, and signs them in' do
      user_count = User.count
      new_user_attrs = attributes_for(:user)
      
      post :create, format: :json, params: { user: new_user_attrs }
      
      # Expect a successful response and a new user in the database
      expect(response).to be_success
      expect(User.count).to eq(user_count + 1)
      user = User.last
      expect(user.email).to eq(new_user_attrs[:email])
      
      parsed_response = JSON.parse(response.body)
      
      # Expect a session hash with an email and auth token
      expect(parsed_response["data"]["session"]["email"]).to eq(user.email)
      expect(parsed_response["data"]["session"]["authentication_token"]).to eq(user.authentication_token)  
    end
    
    it 'requires password confirmation for sign up' do
      new_user_attrs = attributes_for(:user).except(:password_confirmation)
      
      post :create, format: :json, params: { user: new_user_attrs }
      
      expect(response).to have_http_status(:bad_request)
    end
    
    it 'requires unique email for sign up' do
      new_user_attrs = attributes_for(:user).merge({email: traveler.email})
      
      post :create, format: :json, params: { user: new_user_attrs }
      
      expect(response).to have_http_status(:bad_request)
    end
    
    it 'requires password and password confirmation to match' do
      new_user_attrs = attributes_for(:user).merge({password_confirmation: "someotherpw"})
      
      post :create, format: :json, params: { user: new_user_attrs }
      
      expect(response).to have_http_status(:bad_request)
    end
    
  end
    
  describe "user sign in/sign out" do
    
    it 'signs in an existing user' do
      pw = attributes_for(:user)[:password]
      post :new_session, format: :json, params: { user: { email: traveler.email, password: pw } }
      
      expect(response).to be_success
      
      parsed_response = JSON.parse(response.body)
      
      # Expect a session hash with an email and auth token
      expect(parsed_response["data"]["session"]["email"]).to eq(traveler.email)
      expect(parsed_response["data"]["session"]["authentication_token"]).to eq(traveler.authentication_token)  
    end
    
    it 'requires password for sign in' do
      pw = "somerandombadpw"
      post :new_session, format: :json, params: { user: { email: traveler.email, password: pw } }
      
      expect(response).to have_http_status(:bad_request)
    end
    
    it 'signs out a user' do
      original_auth_token = traveler.authentication_token
      
      request.headers['X-User-Token'] = original_auth_token
      request.headers['X-User-Email'] = traveler.email
      delete :end_session, format: :json
      
      expect(response).to be_success
      
      # Expect traveler to have a new auth token after sign out
      traveler.reload
      expect(traveler.authentication_token).not_to eq(original_auth_token)
    end

    it 'requires a valid auth token for sign out' do
      original_auth_token = traveler.authentication_token
      
      request.headers['X-User-Token'] = original_auth_token + "_bloop"
      request.headers['X-User-Email'] = traveler.email
      delete :end_session, format: :json
      
      expect(response).to have_http_status(:unauthorized)
      
      # Expect traveler to have the same auth token
      traveler.reload
      expect(traveler.authentication_token).to eq(original_auth_token)
    end
    
    it 'locks out user after three attempts' do
      
      pw = "somerandombadpw"

      expect(traveler.access_locked?).to be false
      expect(traveler.failed_attempts).to eq(0)
      
      # Attempt 1
      post :new_session, format: :json, params: { user: { email: traveler.email, password: pw } }
      
      traveler.reload
      expect(traveler.access_locked?).to be false
      expect(traveler.failed_attempts).to eq(1)
      
      # Attempt 2
      post :new_session, format: :json, params: { user: { email: traveler.email, password: pw } }

      traveler.reload
      expect(traveler.access_locked?).to be false
      expect(traveler.failed_attempts).to eq(2)
      
      # Attempt 3
      post :new_session, format: :json, params: { user: { email: traveler.email, password: pw } }

      traveler.reload
      expect(traveler.access_locked?).to be true
      expect(traveler.failed_attempts).to eq(3)
      
      # Attempt 4 (with correct pw)
      post :new_session, format: :json, params: { user: { email: traveler.email, password: attributes_for(:user)[:password] } }
      expect(response).to have_http_status(:bad_request)

    end
    
  end
  
  describe "user profile" do
  
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
      expect(parsed_response["trip_types"].first["code"]).to eq("transit")
      expect(parsed_response["trip_types"].first["value"]).to eq(true)
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

    it 'returns the accommodations as false if they are not answered' do
      sign_in english_traveler

      # Set the users accommodations
      english_traveler.update_accommodations({wheelchair: true, jacuzzi: false})

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
      expect(wheelchair_entry['value']).to eq(true)

      # gotta have that Jacuzzi
      expect(jacuzzi_entry['code']).to eq('jacuzzi')
      expect(jacuzzi_entry['value']).to eq(false)
      expect(jacuzzi_entry['name']).to eq('missing key accommodation_jacuzzi_name') # Just make sure we are making the call to get a name
      expect(jacuzzi_entry['note']).to eq('missing key accommodation_jacuzzi_note') # Just make sure we are making the call to get a note
      expect(jacuzzi_entry['question']).to eq('missing key accommodation_jacuzzi_question') # Just make sure we are making the call to get a question
    end 

    it 'returns the users eligibilities as null if they are not answered' do
      sign_in english_traveler
      # Set the users eligibilities
      english_traveler.update_eligibilities({over_65: true})

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

    it 'updates basic attributes for a user' do
      sign_in traveler
      request.headers['X-User-Token'] = traveler.authentication_token
      request.headers['X-User-Email'] = traveler.email

      params = {attributes: {first_name: "Jorge", last_name: "Burdell", email: "gpburdell@email.net", preferred_locale: "en"}, trip_types: {transit: true, paratransit: false}}

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
      expect(traveler.preferred_trip_types).to eq(['transit'])

    end

    it 'updates the password for a user' do
      sign_in traveler
      request.headers['X-User-Token'] = traveler.authentication_token
      request.headers['X-User-Email'] = traveler.email

      params = {attributes: {password: "welcome_55", password_confirmation: "welcome_55"}}

      old_token = traveler.encrypted_password

      put :update, params: params
      
      # Confirm the Response was a Success 
      expect(response).to be_success

      # Refresh the User's Attributes from the DB
      traveler.reload 

      # Confirm that all the attributes were updated
      expect(traveler.encrypted_password).not_to eq(old_token)
    end

    it 'will not update the password because the confirmation does not match' do
      sign_in traveler
      request.headers['X-User-Token'] = traveler.authentication_token
      request.headers['X-User-Email'] = traveler.email

      params = {attributes: {password: "welcome_55", password_confirmation: "welcome_555"}}

      old_token = traveler.encrypted_password

      put :update, params: params
      
      # Confirm the Response
      expect(response.status).to eq(500)

      # Refresh the User's Attributes from the DB
      traveler.reload 

      # Confirm that all the attributes were updated
      expect(traveler.encrypted_password).to eq(old_token)
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
  
  
  describe "password reset" do
    
    it "resets a user's password and sends them an email" do
    
      old_pw_enc = traveler.encrypted_password
    
      expect(User).to receive(:find_by).and_return(traveler)
      expect(UserMailer).to receive(:api_v2_reset_password_instructions)
                        .and_return(UserMailer.api_v2_reset_password_instructions(traveler, "new_password"))
    
      params = { user: { email: traveler.email } }      
      post :reset_password, params: params
      
      traveler.reload
      expect(response).to be_success
      expect(traveler.encrypted_password).not_to eq(old_pw_enc)
    
    end
    
  end
  
  describe "subscribe/unsubscribe" do
    
    it "unsubscribes a user from email updates" do
      
      expect(traveler.subscribed_to_emails).to be true
      
      request.headers['X-User-Token'] = traveler.authentication_token
      request.headers['X-User-Email'] = traveler.email
      
      post :unsubscribe
      
      traveler.reload
      expect(response).to be_success
      expect(traveler.subscribed_to_emails).to be false
      
    end
    
    it "subscribes a user to email updates" do
      traveler.update_attributes(subscribed_to_emails: false)
      
      expect(traveler.subscribed_to_emails).to be false
      
      request.headers['X-User-Token'] = traveler.authentication_token
      request.headers['X-User-Email'] = traveler.email
      
      post :subscribe
      
      traveler.reload
      expect(response).to be_success
      expect(traveler.subscribed_to_emails).to be true
    end
    
  end

end
