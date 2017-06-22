require 'rails_helper'

RSpec.describe Admin::GeographiesController, type: :controller do

  let!(:admin) { FactoryGirl.create :admin }
  let!(:non_admin) { FactoryGirl.create :user }
  let(:counties_file) { fixture_file_upload('spec/files/test_counties.zip', 'application/zip') }
  let(:cities_file) { fixture_file_upload('spec/files/test_cities.zip', 'application/zip') }
  let(:zipcodes_file) { fixture_file_upload('spec/files/test_zipcodes.zip', 'application/zip') }
  let(:custom_geographies_file) { fixture_file_upload('spec/files/test_custom_geos.zip', 'application/zip') }
  
  before(:each) { sign_in admin }

  it 'uploads counties' do
    County.destroy_all
    count = County.count

    params = {geographies: {file: counties_file}}
    post :upload_counties, params: params, format: :js

    expect(County.count).to eq(count + 2)
    expect(response).to have_http_status(302)
  end

  it 'uploads cities' do
    count = City.count

    params = {geographies: {file: cities_file}}
    post :upload_cities, params: params, format: :js
    expect(City.count).to eq(count + 4)
    expect(response).to have_http_status(302)
  end

  it 'uploads zipcodes' do
    count = Zipcode.count

    params = {geographies: {file: zipcodes_file}}
    post :upload_zipcodes, params: params, format: :js

    expect(Zipcode.count).to eq(count + 3)
    expect(response).to have_http_status(302)
  end

  it 'uploads custom geographies' do
    count = CustomGeography.count

    params = {geographies: {file: custom_geographies_file}}
    post :upload_custom_geographies, params: params, format: :js

    expect(CustomGeography.count).to eq(count + 1)
    expect(response).to have_http_status(302)
  end
  
  it 'allows search of geographies via autocomplete action' do    
    county = create(:county)
    city = create(:city)
    zipcode = create(:zipcode)

    # Search returns county results by name and state
    get :autocomplete, format: :json, params: {term: "#{county.name}, #{county.state}"}
    response_body = JSON.parse(response.body)
    expect(response_body.length).to be > 0

    # Search returns city results by name and state
    get :autocomplete, format: :json, params: {term: "#{city.name}, #{city.state}"}
    response_body = JSON.parse(response.body)
    expect(response_body.length).to be > 0

    # Search returns zipcode resuls
    get :autocomplete, format: :json, params: {term: zipcode.name}
    response_body = JSON.parse(response.body)
    expect(response_body.length).to be > 0
  end

end
