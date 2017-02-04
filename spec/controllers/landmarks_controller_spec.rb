require 'rails_helper'

RSpec.describe LandmarksController, type: :controller do

  it 'updates the landmarks' do
    params = {landmarks: {file: 'spec/files/good_landmarks.csv'}}
    patch :update_all, params: params, format: :js

    # test for the 200 status-code
    expect(response).to be_success

    # Confirm that the variable was set correctly
    expect(Landmark.count).to eq(3)
  end
  
end