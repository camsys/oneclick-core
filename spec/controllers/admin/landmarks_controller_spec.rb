require 'rails_helper'

RSpec.describe Admin::LandmarksController, type: :controller do
  
  let(:admin) { create(:admin) }
  let(:staff) { create(:staff_user) }
  let(:traveler) { create(:user) }
  
  context "while signed in as an admin" do
    
    before(:each) { sign_in admin }
    
    it 'updates the landmarks' do
      params = {landmarks: {file: 'spec/files/good_landmarks.csv'}}
      patch :update_all, params: params, format: :js

      # test for the 200 status-code
      expect(response).to be_success

      # Confirm that the variable was set correctly
      expect(Landmark.count).to eq(3)
    end
    
  end
  
  context "while signed in as a staff" do
    
    before(:each) { sign_in staff }
    
    it 'prevents landmarks from being updated by a staff' do
      params = {landmarks: {file: 'spec/files/good_landmarks.csv'}}
      patch :update_all, params: params, format: :js

      # The response should be a re-direct
      expect(response).to have_http_status(:unauthorized)

      # Confirm that the landmarks were not loaded
      expect(Landmark.count).to eq(0)
    end
    
    it "prevents staff from viewing the landmarks page" do
      get :index
      expect(response).to have_http_status(:unauthorized)      
    end
  
  end
  
  context "while signed in as a traveler" do
    
    before(:each) { sign_in traveler }
    
    it "prevents travelers from viewing the landmarks page" do
      get :index
      expect(response).to have_http_status(:unauthorized)      
    end
    
  end
  
end
