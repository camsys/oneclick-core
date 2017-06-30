require 'rails_helper'

RSpec.describe Admin::ConfigsController, type: :controller do

  let(:admin) { create(:admin) }
  let(:staff) { create(:staff_user) }
  let(:traveler) { create(:user) }
  let!(:config) { create :config, key: "open_trip_planner", value: nil }
  
  context "while signed in as an admin" do
    
    before(:each) { sign_in admin }
    
    it 'sets the open_trip_planner config' do
      params = {config: {value: 'http://otp-url.com'}}
      patch :set_open_trip_planner, params: params, format: :js

      # test for the 200 status-code
      expect(response).to be_success

      # Confirm that the variable was set correctly
      expect(Config.find_by(key: "open_trip_planner").value).to eq('http://otp-url.com')
    end
    
    it 'sets the tff_ppi_key config' do
      params = {config: {value: 'SECRETKEYS'}}
      patch :set_tff_api_key, params: params, format: :js

      # test for the 200 status-code
      expect(response).to be_success

      # Confirm that the variable was set correctly
      expect(Config.find_by(key: "tff_api_key").value).to eq('SECRETKEYS')
    end
    
    it 'sets the uber token config' do
      params = {config: {value: 'UBERTOKEN'}}
      patch :set_uber_token, params: params, format: :js

      # test for the 200 status-code
      expect(response).to be_success

      # Confirm that the variable was set correctly
      expect(Config.find_by(key: "uber_token").value).to eq('UBERTOKEN')
    end
    
  end

  context "while signed in as a staff" do
    
    before(:each) { sign_in staff }
    
    it 'prevents staff from viewing config page' do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
    
    it 'prevents configs from being updated by a staff' do
      params = {config: {value: 'http://otp-BAD-url.com'}}
      patch :set_open_trip_planner, params: params, format: :js

      # The response should be a re-direct
      expect(response).to have_http_status(:unauthorized)

      # Confirm that the variable was NOT set
      expect(Config.find_by(key: "open_trip_planner").value).not_to eq('http://otp-BAD-url.com')
    end
    
  end
  
  context "while signed in as a traveler" do
    
    before(:each) { sign_in traveler }
    
    it 'prevents traveler from viewing config page' do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
    
  end

end
