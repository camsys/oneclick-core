require 'rails_helper'

RSpec.describe Api::V1::SessionsController, type: :controller do
  # This line is necessary to get Devise scoped tests to work.
  before(:each) { @request.env["devise.mapping"] = Devise.mappings[:user] }
  let(:user) { create(:user) }

  it 'allows user sign_in requests and returns an auth token' do    
    post :create, params: {
      "user": {
          "email": user.email,
          "password": user.password
        }
    }, as: :json
    response_body = JSON.parse(response.body)

    expect(response).to be_success    # test for the 200 status-code
    expect( response_body &&
            response_body["authentication_token"] &&
            response_body["email"]).to be # Should return an auth token and email
    expect(response_body["authentication_token"]).to eq(user.authentication_token) # Expect returned auth token to match that of user.
    expect(response_body["email"]).to eq(user.email) # Expect returned email to match that of user.
  end

  it 'allows user sign_out requests and refreshes auth token' do
    token = user.authentication_token # Sign in user and get their auth token
    delete :destroy, params: { user_email: user.email, user_token: token} # Sign out user
    expect(response).to be_success     # test for the 200 status-code

    user.reload # Reload user (required for rspec model updates)
    expect(user.authentication_token).not_to eq(token) # User should have a new auth token now
  end

end
