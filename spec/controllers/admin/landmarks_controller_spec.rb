require 'rails_helper'

RSpec.describe Admin::LandmarksController, type: :controller do

  let!(:admin) { FactoryGirl.create :admin }
  let!(:non_admin) { FactoryGirl.create :user }

  it 'updates the landmarks' do
    sign_in admin 

    params = {landmarks: {file: 'spec/files/good_landmarks.csv'}}
    patch :update_all, params: params, format: :js

    # test for the 200 status-code
    expect(response).to be_success

    # Confirm that the variable was set correctly
    expect(Landmark.count).to eq(3)
  end

  it 'prevents landmarks from being updated by a non-admin' do
    sign_in non_admin

    params = {landmarks: {file: 'spec/files/good_landmarks.csv'}}
    patch :update_all, params: params, format: :js

    # The response should be a re-direct
    expect(response).to have_http_status(302)

    # Confirm that the landmarks were not loaded
    expect(Landmark.count).to eq(0)
  end
  
end