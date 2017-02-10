require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do

  let!(:admin) { FactoryGirl.create :admin }
  let!(:non_admin) { FactoryGirl.create :user }
  
  it 'gets a list of all the staff' do
    sign_in admin

    get :index

    # The response should be a re-direct
    expect(response).to be_success
  end

  it 'staff list cannot be viewed by a non-admin' do
    sign_in non_admin

    get :index

    # The response should be a re-direct
    expect(response).to have_http_status(302)
  end
  
end