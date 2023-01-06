require 'rails_helper'

RSpec.describe Admin::LandmarksController, type: :controller do

  let(:superuser) { create(:superuser) }
  let(:staff) { create(:staff_user) }
  let(:traveler) { create(:user) }
  let(:work) { create(:landmark) }
  let(:valid_landmark_params) {{name: "new landmark", lat: 30, lng: 30}}
  let(:invalid_landmark_params_one) {{lat: 30, lng: 30}}
  let(:invalid_landmark_params_two) {{name: "new landmark", lat: 2000, lng: 30}}

  context "while signed in as a superuser" do

    before(:each) { sign_in superuser }

    it 'updates the landmarks' do
      params = {landmarks: {file: 'spec/files/good_landmarks.csv'}}
      patch :update_all, params: params, format: :js

      # test for the 200 status-code
      expect(response).to be_success

      # Confirm that the variable was set correctly
      expect(Landmark.count).to eq(3)
    end

    it 'deletes a landmark' do
      work.name = "test"
      landmark_count = Landmark.count
      delete :destroy, params: { id: work.id }
      expect(Landmark.all.count).to eq(landmark_count - 1)
    end

    it 'creates a valid landmark' do
      landmark_count = Landmark.count
      post :create, params: { landmark: valid_landmark_params }
      expect(Landmark.count).to eq(landmark_count + 1)
      expect(Landmark.last.name).to eq("new landmark")
    end

    it 'creates an invalid landmark one' do
      landmark_count = Landmark.count
      post :create, params: { landmark: invalid_landmark_params_one }
      expect(Landmark.count).to eq(landmark_count)
    end

    it 'creates an invalid landmark two' do
      landmark_count = Landmark.count
      post :create, params: { landmark: invalid_landmark_params_two }
      expect(Landmark.count).to eq(landmark_count)
    end

    it 'updates a landmark' do
      post :update, params: { id: work.id, landmark: { name: "new landmark name" }}
      work.reload
      expect(work.name).to eq("new landmark name")
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

    it 'deletes a landmark' do
      work.name = "test"
      landmark_count = Landmark.all.count
      delete :destroy, params: { id: work.id }
      expect(Landmark.all.count).to eq(landmark_count)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates a valid landmark' do
      landmark_count = Landmark.count
      post :create, params: { landmark: valid_landmark_params }
      expect(Landmark.count).to eq(landmark_count)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates an invalid landmark one' do
      landmark_count = Landmark.count
      post :create, params: { landmark: invalid_landmark_params_one }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates an invalid landmark two' do
      landmark_count = Landmark.count
      post :create, params: { landmark: invalid_landmark_params_two }
      expect(response).to have_http_status(:unauthorized)
    end

  end

  context "while signed in as a traveler" do

    before(:each) { sign_in traveler }

    it "prevents travelers from viewing the landmarks page" do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end

    it 'deletes a landmark' do
      work.name = "test"
      landmark_count = Landmark.all.count
      delete :destroy, params: { id: work.id }
      expect(Landmark.all.count).to eq(landmark_count)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates a valid landmark' do
      landmark_count = Landmark.count
      post :create, params: { landmark: valid_landmark_params }
      expect(Landmark.count).to eq(landmark_count)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates an invalid landmark one' do
      landmark_count = Landmark.count
      post :create, params: { landmark: invalid_landmark_params_one }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates an invalid landmark two' do
      landmark_count = Landmark.count
      post :create, params: { landmark: invalid_landmark_params_two }
      expect(response).to have_http_status(:unauthorized)
    end

  end

end
