require 'rails_helper'
require 'helpers/api_v1_helpers'

# Provides user api_sign_in and auth_token helper methods
RSpec.configure do |config|
  config.include Api::V1::Helpers
end

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
  end

  it 'allows user sign_out requests' do
    token = auth_token(user) # Sign in user and get their auth token
    delete :destroy, params: { user_token: token}

    expect(response).to be_success     # test for the 200 status-code
  end

end
