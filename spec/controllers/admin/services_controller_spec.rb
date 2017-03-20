require 'rails_helper'

RSpec.describe Admin::ServicesController, type: :controller do

  let!(:admin) { FactoryGirl.create :admin }
  let!(:non_admin) { FactoryGirl.create :user }
  before(:each) { sign_in admin }
  let(:service) { create(:service) }

  it 'gets a list of all the services' do
    get :index
    expect(response).to be_success
  end

  it 'services list cannot be viewed by a non-admin' do
    sign_in non_admin

    get :index

    # The response should be a re-direct
    expect(response).to have_http_status(302)
  end

  it 'shows an individual service' do

    get :show, params: {id: service.id}
    expect(response).to be_success

  end

  it 'faithfully creates a transit service based on passed parameters' do
    attrs = attributes_for(:transit_service)
    params = {transit: attrs}
    count = Transit.count

    post :create, params: params

    # test for the 302 status-code (redirect)
    expect(response).to have_http_status(302)

    # Confirm that a new service was created
    expect(Transit.count).to eq(count + 1)

    # Confirm that the most recently created service matches the parameters sent
    @service = Transit.last
    attributes_match = attrs.all? { |att| attrs[att] == @service[att] }
    expect(attributes_match).to be true
  end

  it 'faithfully creates a paratransit service based on passed parameters' do
    attrs = attributes_for(:paratransit_service)
    params = {paratransit: attrs}
    count = Paratransit.count

    post :create, params: params

    # test for the 302 status-code (redirect)
    expect(response).to have_http_status(302)

    # Confirm that a new service was created
    expect(Paratransit.count).to eq(count + 1)

    # Confirm that the most recently created service matches the parameters sent
    @service = Paratransit.last
    attributes_match = attrs.all? { |att| attrs[att] == @service[att] }
    expect(attributes_match).to be true
  end

   it 'faithfully creates a taxi service based on passed parameters' do
     attrs = attributes_for(:taxi_service)
     params = {taxi: attrs}
     count = Taxi.count
  
     post :create, params: params
  
     # test for the 302 status-code (redirect)
     expect(response).to have_http_status(302)

     # Confirm that a new service was created
     expect(Taxi.count).to eq(count + 1)
  
     # Confirm that the most recently created service matches the parameters sent
     @service = Taxi.last
     attributes_match = attrs.all? { |att| attrs[att] == @service[att] }
     expect(attributes_match).to be true
   end

  it 'destroys a service' do
    service
    count = Service.count

    delete :destroy, params: { id: service.id }
    expect(response).to have_http_status(302)

    # Confirm that the service was destroyed
    expect(Service.count).to eq(count - 1)

  end

  it 'updates a service' do
    update_attrs = attributes_for(:different_service)

    update_params = {
      id: service.id,
      service: update_attrs
    }
    put :update, params: update_params
    expect(response).to have_http_status(302)
    service.reload

    attributes_match = update_attrs.all? { |att| update_attrs[att] == service[att] }
    expect(attributes_match).to be true

  end

  it "updates a service's coverage areas" do
    old_start_or_end_area = service.start_or_end_area
    new_region_recipe = attributes_for(:region_2)[:recipe].to_json
    update_params = {
      id: service.id,
      service: {
        start_or_end_area_attributes: {
          recipe: new_region_recipe
        }
      }
    }
    put :update, params: update_params
    expect(response).to have_http_status(302)
    service.reload

    new_start_or_end_area = service.start_or_end_area

    expect(old_start_or_end_area).not_to eq(new_start_or_end_area)
  end

  it 'allows search of geographies via show action' do
    county = create(:county)
    city = create(:city)
    zipcode = create(:zipcode)

    # Search returns county results by name and state
    get :show, format: :json, params: {id: service.id, term: "#{county.name}, #{county.state}"}
    response_body = JSON.parse(response.body)
    expect(response_body.length).to be > 0

    # Search returns city results by name and state
    get :show, format: :json, params: {id: service.id, term: "#{city.name}, #{city.state}"}
    response_body = JSON.parse(response.body)
    expect(response_body.length).to be > 0

    # Search returns zipcode resuls
    get :show, format: :json, params: {id: service.id, term: zipcode.name}
    response_body = JSON.parse(response.body)
    expect(response_body.length).to be > 0

  end

end
