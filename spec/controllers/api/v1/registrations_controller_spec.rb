require 'rails_helper'

RSpec.describe Api::V1::RegistrationsController, type: :controller do
  # This line is necessary to get Devise scoped tests to work.
  before(:each) { @request.env["devise.mapping"] = Devise.mappings[:user] }

  let(:user_attrs) { attributes_for(:user) }

  it 'allows user sign_up requests' do
    post :create, params: { user: user_attrs }, as: :json
    response_body = JSON.parse(response.body)

    expect(response).to be_success    # test for the 200 status-code
    expect(response_body).to be       # test for response body
    expect(response_body["id"]).to be # test for id from created user
  end
  
end
