require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do

  let(:traveler) { create :user }
  let(:english_traveler) { create(:english_speaker) }
  let!(:over_65) { create :eligibility }
  let!(:veteran) { create :veteran } 
  let!(:jacuzzi) { create :jacuzzi }
  let!(:wheelchair) { create :wheelchair }
  let(:service) { create :paratransit_service, :ride_pilot_bookable }
  let(:trapeze_service) { create :paratransit_service, :trapeze_bookable }
  
  let(:auth_headers) { {
    'X-User-Token' => traveler.authentication_token,
    'X-User-Email' => traveler.email
  } }
  let(:eng_auth_headers) { {
    'X-User-Token' => english_traveler.authentication_token,
    'X-User-Email' => english_traveler.email
  } }
  

  describe 'profile' do

    it 'returns the first and last name of a user profile' do
      first_name = traveler.first_name
      last_name = traveler.last_name

      request.headers.merge!(auth_headers)
      get :profile, format: :json

      # test for the 200 status-code
      expect(response).to be_success

      # Check on a specific translation
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["first_name"]).to eq(first_name)
      expect(parsed_response["last_name"]).to eq(last_name)
    end

    it 'returns the preferred locale' do
      request.headers.merge!(eng_auth_headers)
      get :profile, format: :json

      # test for the 200 status-code
      expect(response).to be_success

      # Check on a specific translation
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["lang"]).to eq("en")
    end

    it 'returns the preferred trip types' do
      request.headers.merge!(eng_auth_headers)
      get :profile, format: :json

      # test for the 200 status-code
      expect(response).to be_success

      # Check on a specific translation
      parsed_response = JSON.parse(response.body)
      # There should be 2 preferred modes
      expect(parsed_response["preferred_modes"].count).to eq(2)
      # transit should be preferred mode (Depracated after api/v1)
      expect('mode_transit'.in? parsed_response["preferred_modes"]).to eq(true)
      # transit should be preferred trip type
      expect('transit'.in? parsed_response["preferred_trip_types"]).to eq(true)
      # unicycle should be preferred (Depracated after api/v1)
      expect('mode_unicycle'.in? parsed_response["preferred_modes"]).to eq(true)
      # unicycle should be preferred trip type
      expect('unicycle'.in? parsed_response["preferred_trip_types"]).to eq(true)
      # it should not include car (Depracated after api/v1)
      expect('mode_car'.in? parsed_response["preferred_modes"]).to eq(false)
      # it should not include car
      expect('car'.in? parsed_response["preferred_trip_types"]).to eq(false)
    end

    it 'returns the users eligibilities' do
      # Set the users eligibilities
      english_traveler.update_eligibilities({over_65: true, veteran: false})
      request.headers.merge!(eng_auth_headers)
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
      # Set the users accommodations
      english_traveler.update_accommodations({wheelchair: true, jacuzzi: true})
      request.headers.merge!(eng_auth_headers)
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

  end


  describe 'update' do
    
    before(:each) do
      request.headers.merge!(auth_headers)
    end

    it 'updates basic attributes for a user' do
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
    
    it 'updates Ridepilot user booking profile' do
      # Stub UserBookingProfile to always return true on authenticate? call
      UserBookingProfile.any_instance.stub(:authenticate?).and_return(true)
      
      expect(traveler.booking_profiles.count).to eq(0)

      params = {booking: [{service_id: service.id, user_name: "0", password: "RIDEPILOTTOKEN"}]}
      post :update, params: params
      
      expect(response).to be_success        
      expect(traveler.booking_profiles.count).to eq(1)
      expect(traveler.booking_profile_for(service)).to be_a(UserBookingProfile)
    end

    it 'updates trapeze user booking profile' do
      # Stub UserBookingProfile to always return true on authenticate? call
      UserBookingProfile.any_instance.stub(:authenticate?).and_return(true)
      
      expect(traveler.booking_profiles.count).to eq(0)

      params = {booking: [{service_id: trapeze_service.id, user_name: "0", password: "TrapezeTOKEN"}]}
      post :update, params: params
      
      expect(response).to be_success        
      expect(traveler.booking_profiles.count).to eq(1)
      expect(traveler.booking_profile_for(trapeze_service)).to be_a(UserBookingProfile)
    end
    
    it 'returns failure code if user booking profile not authenticated' do
      # Stub UserBookingProfile to always return false on authenticate? call
      UserBookingProfile.any_instance.stub(:authenticate?).and_return(false)

      expect(traveler.booking_profiles.count).to eq(0)

      params = {booking: [{service_id: service.id, user_name: "0", password: "RIDEPILOTTOKEN"}]}
      post :update, params: params
      
      expect(response).to have_http_status(400)        
      expect(traveler.booking_profiles.count).to eq(0)
    end
    
  end
  
  
  
  describe 'password' do
    
    before(:each) do
      request.headers.merge!(auth_headers)
    end

    it 'updates the password for a user' do
      old_token = traveler.encrypted_password

      params = {"password":"welcome2","password_confirmation":"welcome2"}

      post :password, params: params
      
      # Confirm the Response was a Success 
      expect(response).to be_success

      # Refresh the User's Attributes from the DB
      traveler.reload 

      # Confirm that all the attributes were updated
      expect(traveler.encrypted_password).not_to eq(old_token)
    end

    it 'will not updates the password for a user because the password confirmation does not match' do
      old_token = traveler.encrypted_password

      params = {"password":"welcome2","password_confirmation":"welcome3"}

      post :password, params: params
      
      # Confirm the Response was a Success 
      expect(response.code).to eq("406")

      # Refresh the User's Attributes from the DB
      traveler.reload 

      # Confirm that all the attributes were updated
      expect(traveler.encrypted_password).to eq(old_token)
    end

    it 'will not update the password because the confirmation is missing' do
      old_token = traveler.encrypted_password

      params = {"password":"welcome2"}

      post :password, params: params
      
      # Confirm the Response was a Success 
      expect(response.code).to eq("400")

      # Refresh the User's Attributes from the DB
      traveler.reload 

      # Confirm that all the attributes were updated
      expect(traveler.encrypted_password).to eq(old_token)
    end

    it 'will not update the password because the password is too short' do
      old_token = traveler.encrypted_password

      params = {"password":"5","password_confirmation":"5"}

      post :password, params: params
      
      # Confirm the Response was a Success 
      expect(response.code).to eq("406")
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["message"]).to eq("Unacceptable Password")

      # Refresh the User's Attributes from the DB
      traveler.reload 

      # Confirm that all the attributes were updated
      expect(traveler.encrypted_password).to eq(old_token)
    end
  
    it 'sends a password reset email and sets a reset token' do
      
      # PW reset token should start nil
      expect(traveler.reset_password_token).to be_nil
      
      # During the call, UserMailer should be called to send the reset instructions email
      expect(UserMailer).to receive(:api_v1_reset_password_instructions)
                        .and_return(UserMailer.api_v1_reset_password_instructions(traveler, "token"))
      
      post :request_reset, params: { "email": traveler.email }
      expect(response).to be_success
      
      # After API call, reset token should not be nil anymore
      traveler.reload
      expect(traveler.reset_password_token).to be
    end
    
    it 'resets password with token' do
      old_pw_enc = traveler.encrypted_password
      
      # Send the reset password instructions and set the reset token
      token = traveler.send_api_v1_reset_password_instructions
      
      params = {
        "reset_password_token": token,
        "password": "newpassword1",
        "password_confirmation": "newpassword1"
      }
      
      post :reset, params: params
      traveler.reload
      
      # Expect response to be success, reset token to set to nil, and password to change
      expect(response).to be_success
      expect(traveler.reset_password_token).to be nil
      expect(traveler.encrypted_password).not_to eq(old_pw_enc)
    end
    
  end
    
  
  describe 'get guest token' do

    it 'creates a new guest user' do
      user_count = User.count
      get :get_guest_token
      expect(response).to be_success
      expect(User.count).to eq(user_count + 1)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["email"]).to be
      expect(parsed_response["authentication_token"]).to be
    end
    
  end

end
