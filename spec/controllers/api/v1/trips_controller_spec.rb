require 'rails_helper'

RSpec.describe Api::V1::TripsController, type: :controller do
  pending "Add Trips Controller Tests"

  it 'accepts plan calls' do
    post :create
    expect(response).to be_success
  end

end
