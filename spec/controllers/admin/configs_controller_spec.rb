require 'rails_helper'

RSpec.describe Admin::ConfigsController, type: :controller do

  let!(:admin) { FactoryGirl.create :admin }
  let!(:non_admin) { FactoryGirl.create :user }

  it 'sets the open_trip_planner config' do
    sign_in admin
    params = {config: {value: 'http://otp-url.com'}}
    patch :set_open_trip_planner, params: params, format: :js

    # test for the 200 status-code
    expect(response).to be_success

    # Confirm that the variable was set correctly
    expect(Config.find_by(key: "open_trip_planner").value).to eq('http://otp-url.com')
  end

  it 'prevents configs from being updated by a non-admin' do
    sign_in non_admin

    params = {config: {value: 'http://otp-BAD-url.com'}}
    patch :set_open_trip_planner, params: params, format: :js

    # The response should be a re-direct
    expect(response).to have_http_status(302)

    # Confirm that the variable was NOT set
    expect(Config.find_by(key: "open_trip_planner").value).not_to eq('http://otp-BAD-url.com')
  end

end
