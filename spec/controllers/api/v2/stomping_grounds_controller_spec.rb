require 'rails_helper'

RSpec.describe Api::V2::StompingGroundsController, type: :controller do

  let(:traveler) { create(:english_speaker) }
  let!(:home) { create(:home_place) }
  let!(:work) { create(:stomping_ground) }
  let(:doctor_location) {JSON.parse(File.read("spec/files/doctor_location.json"))}

  it 'indexes the the users stomping grounds' do
    # Assign these Stomping Grounds
    home.user = traveler
    work.user = traveler
    home.save
    work.save 

    sign_in traveler
    request.headers['X-User-Token'] = traveler.authentication_token
    request.headers['X-User-Email'] = traveler.email

    get :index
    
    # Confirm the Response was a Success 
    expect(response).to be_success

    parsed_response = JSON.parse(response.body)
    expect(parsed_response["data"].count).to eq(2)
  end

  it 'has all the correct attributes on the index' do
    # Assign these Stomping Grounds
    work.user = traveler
    work.save 

    sign_in traveler
    request.headers['X-User-Token'] = traveler.authentication_token
    request.headers['X-User-Email'] = traveler.email

    get :index
    
    # Confirm the Response was a Success 
    expect(response).to be_success
    parsed_response = JSON.parse(response.body)
    place = parsed_response["data"].first
    expect(parsed_response["data"].count).to eq(1)
    expect(place["name"]).to eq("Work")
    expect(place["formatted_address"]).to eq("101 Station Landing, Medford, MA 02155")
    expect(place["address_components"]).to be
    expect(place["geometry"]["location"]["lat"]).to eq(42.401697)
    expect(place["geometry"]["location"]["lng"]).to eq(-71.081818)

  end

  it 'deletes a stomping ground' do
    # Assign these Stomping Grounds
    home.user = traveler
    work.user = traveler
    home.save
    work.save 

    sign_in traveler
    request.headers['X-User-Token'] = traveler.authentication_token
    request.headers['X-User-Email'] = traveler.email

    expect(traveler.stomping_grounds.count).to eq(2)
    delete :destroy, params: { id: home.id} # Sign out user
    expect(response).to be_success
    expect(traveler.stomping_grounds.count).to eq(1)
  end

  it 'creates a stomping ground' do
    sign_in traveler
    request.headers['X-User-Token'] = traveler.authentication_token
    request.headers['X-User-Email'] = traveler.email
    expect(traveler.stomping_grounds.count).to eq(0)
    post :create, params: {stomping_ground: doctor_location}
    expect(traveler.stomping_grounds.count).to eq(1)
    expect(traveler.stomping_grounds.first.name).to eq('Doctor')
  end

  it 'updates a stomping ground' do
    home.user = traveler
    home.save
    sign_in traveler
    request.headers['X-User-Token'] = traveler.authentication_token
    request.headers['X-User-Email'] = traveler.email
    expect(traveler.stomping_grounds.count).to eq(1)
    patch :update, params: {id: home.id, stomping_ground: doctor_location}
    expect(traveler.stomping_grounds.count).to eq(1)
    expect(traveler.stomping_grounds.first.name).to eq('Doctor')
  end
  
end
