require 'rails_helper'

RSpec.describe Api::ApiController, type: :controller do
  # This line is necessary to get Devise scoped tests to work.
  before(:each) { @request.env["devise.mapping"] = Devise.mappings[:user] }
  let(:user) { create(:user) }
  let(:request_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => user.authentication_token} }
  let(:bad_request_headers) { {"X-USER-EMAIL" => user.email, "X-USER-TOKEN" => "abcdefghijklmnop"} }

  it 'authenticates user from token & sets @traveler' do
    expect(controller.traveler).to be_nil
    request.headers.merge!(request_headers) # Send user email and token headers
    controller.authenticate_user_from_token
    expect(controller.traveler.email).to eq(request.headers["X-User-Email"])
  end

  it 'does not set traveler if bad token is passed' do
    expect(controller.traveler).to be_nil
    request.headers.merge!(bad_request_headers) # Send user email and token headers
    controller.authenticate_user_from_token
    expect(controller.traveler).to be_nil
  end
  
end
