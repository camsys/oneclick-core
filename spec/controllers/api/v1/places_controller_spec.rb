require 'rails_helper'

RSpec.describe Api::V1::PlacesController, type: :controller do
  let!(:landmark) { create :landmark }

  it 'searches for cambridge systematics landmark' do
    get :search, search_string: "%Cambridge%", format: :json

    json = JSON.parse(response.body)

    # test for the 200 status-code
    expect(response).to be_success

    # There is only one search that matches
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['record_count']).to eq(1)
  end

  it 'searches for a landmark that does not exist' do
    get :search, search_string: "%blah%", format: :json

    json = JSON.parse(response.body)

    # test for the 200 status-code
    expect(response).to be_success

    # There should be ZERO results
    parsed_response = JSON.parse(response.body)
    expect(parsed_response['record_count']).to eq(0)
  end

end
