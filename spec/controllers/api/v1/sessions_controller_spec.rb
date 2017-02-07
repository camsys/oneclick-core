require 'rails_helper'

RSpec.describe Api::V1::SessionsController, type: :controller do
  # This line is necessary to get Devise scoped tests to work.
  before(:each) { @request.env["devise.mapping"] = Devise.mappings[:user] }

  let(:user_attrs) { attributes_for(:user) }

  it 'allows user sign_in requests' do
    post :create, params: user_attrs, as: :json # DON'T wrap attrs in a user object
    response_body = JSON.parse(response.body)

    expect(response).to be_success    # test for the 200 status-code
  end

  # it 'allows user sign_out requests' do
  #   delete :destroy
  # end

end
