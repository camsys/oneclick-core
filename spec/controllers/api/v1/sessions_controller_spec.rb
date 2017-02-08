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
  end

  # it 'allows user sign_out requests' do
  #   delete :destroy
  # end

end
