require 'rails_helper'

RSpec.describe Admin::ConfigsController, type: :controller do

  let(:admin) { create(:admin) }
  let(:staff) { create(:staff_user) }
  let(:traveler) { create(:user) }
  let!(:config) { create :config, key: "open_trip_planner", value: nil }
  
  context "while signed in as an admin" do
    
    before(:each) { sign_in admin }
    
    it 'sets string configs' do
      params = {  config: { open_trip_planner: 'http://otp-url.com',
                            tff_api_key: 'SECRETKEYS',
                            uber_token: 'UBERTOKEN',
                            lyft_client_token: 'LYFTTOKEN'}, 
                  partial_path: "admin/configs/_trip_planning_apis" }
      patch :update, params: params

      # test for the 200 status-code
      expect(response).to be_success

      # Confirm that the variable was set correctly
      expect(Config.find_by(key: "open_trip_planner").value).to eq('http://otp-url.com')
      expect(Config.find_by(key: "tff_api_key").value).to eq('SECRETKEYS')
      expect(Config.find_by(key: "uber_token").value).to eq('UBERTOKEN')
      expect(Config.find_by(key: "lyft_client_token").value).to eq('LYFTTOKEN')
    end
    
    it 'sets array configs' do
      params = {  config: { daily_scheduled_tasks: ["task1", "task2", "task3"] }, 
                  partial_path: "admin/configs/_trip_planning_apis" }
      patch :update, params: params

      # test for the 200 status-code
      expect(response).to be_success

      # Confirm that the variable was set correctly
      expect(Config.find_by(key: "daily_scheduled_tasks").value).to eq([:task1, :task2, :task3])
    end

  end

  context "while signed in as a staff" do
    
    before(:each) { sign_in staff }
    
    it 'prevents staff from viewing config page' do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
    
    it 'prevents configs from being updated by a staff' do
      params = {config: {open_trip_planner: 'http://otp-BAD-url.com'}, partial_path: "admin/configs/_trip_planning_apis"}
      patch :update, params: params

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
