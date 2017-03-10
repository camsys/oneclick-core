require 'rails_helper'

RSpec.describe Admin::GeographiesController, type: :controller do

  let!(:admin) { FactoryGirl.create :admin }
  let!(:non_admin) { FactoryGirl.create :user }
  let(:counties_file) { fixture_file_upload('spec/files/ma_counties.zip', 'application/zip') }
  let(:cities_file) { fixture_file_upload('spec/files/ma_cities.zip', 'application/zip') }
  let(:zipcodes_file) { fixture_file_upload('spec/files/ma_zipcodes.zip', 'application/zip') }

  it 'uploads counties' do
    sign_in admin

    expect(County.count).to eq(0)

    params = {geographies: {file: counties_file}}
    post :upload_counties, params: params, format: :js

    expect(County.count).to eq(14)
    expect(response).to have_http_status(302)
  end

  it 'uploads cities' do
    sign_in admin

    expect(City.count).to eq(0)

    params = {geographies: {file: cities_file}}
    post :upload_cities, params: params, format: :js
    expect(City.count).to eq(54)
    expect(response).to have_http_status(302)
  end

  it 'uploads zipcodes' do
    sign_in admin

    expect(Zipcode.count).to eq(0)

    params = {geographies: {file: zipcodes_file}}
    post :upload_zipcodes, params: params, format: :js

    expect(Zipcode.count).to eq(139)
    expect(response).to have_http_status(302)
  end

end
