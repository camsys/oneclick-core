require 'rails_helper'

RSpec.describe ConfigsController, type: :controller do

  it 'sets the open_trip_planner config' do
    params = {config: {value: 'http://otp-url.com'}}
    patch :set_open_trip_planner, params: params, format: :js

    # test for the 200 status-code
    expect(response).to be_success

    # Confirm that the variable was set correctly
    expect(Config.find_by(key: "open_trip_planner").value).to eq('http://otp-url.com')
  end
  
end