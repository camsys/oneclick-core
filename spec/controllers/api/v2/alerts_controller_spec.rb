require 'rails_helper'

RSpec.describe Api::V2::AlertsController, type: :controller do

  let!(:user) { create(:english_speaker) }
  let(:request_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }
  let!(:alert) { create(:alert) }
  let!(:expired_alert) { create(:expired_alert) }
  let!(:alert_for_traveler) { create(:alert_for_traveler) }

  it "gets a list of alerts for non-logged in user" do
    get :index, format: :json
    json = JSON.parse(response.body)
    # test for the 200 status-code
    expect(response).to be_success
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['data']['user_alerts'].count).to eq(1)
  end

  it "gets a list of alerts for a logged in user" do
    alert_for_traveler.handle_specific_users
    sign_in user
    request.headers.merge!(request_headers) # Send user email and token headers
    get :index, format: :json
    json = JSON.parse(response.body)
    # test for the 200 status-code
    expect(response).to be_success
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['data']['user_alerts'].count).to eq(2)
  end

  it "acknowledges an alert" do

    # Prelimary Stuff
    alert_for_traveler.handle_specific_users # Create the user_alert
    sign_in user
    request.headers.merge!(request_headers) # Send user email and token headers
    
    # Run index and we should get two items returned
    get :index, format: :json
    json = JSON.parse(response.body)
    # test for the 200 status-code
    expect(response).to be_success
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['data']['user_alerts'].count).to eq(2)
    
    # Grab the id of the first item that was returned
    alert_id = parsed_response['data']['user_alerts'].first["id"]
    
    # Acknowledge that alert
    params =  {
               id: alert_id,
               "user_alert": {
                 "acknowledged": true
                }
              }
    
    put :update, params: params, form: :json
    expect(response).to be_success
   
    # Run index again, and we should only get 1 alert returned.
    get :index, format: :json
    json = JSON.parse(response.body)
    # test for the 200 status-code
    expect(response).to be_success
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['data']['user_alerts'].count).to eq(1)
    alert_id = parsed_response['data']['user_alerts'].first["id"]

  end

end