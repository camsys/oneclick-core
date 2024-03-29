require 'rails_helper'

# NOTE: The current tests don't test oversight agency associations so we'll need to add those at some point
RSpec.describe Admin::ServicesController, type: :controller do

  let!(:agency) { create(:transportation_agency, :with_services)}
  let!(:agency2) { create(:transportation_agency)}
  let!(:oversight_agency) { create(:oversight_agency)}
  let!(:staff_service) { agency.services.first }
  let!(:other_service) { create(:paratransit_service, agency: agency2) }
  let!(:service) { create(:service) }
  
  let(:superuser) { create(:superuser) }
  let(:staff) { create(:staff_user, staff_agency: agency) }
  let(:traveler) { create(:user) }
  let(:wheelchair) { create(:wheelchair)}


  context "while signed in as a superuser" do
    
    before(:each) { sign_in superuser }
    
    it 'gets a list of all the services' do
      get :index
      expect(response).to be_success
      expect(assigns(:services).count).to eq(Service.all.count)
    end

    it 'shows an individual service' do
      get :show, params: {id: service.id}
      expect(response).to be_success
    end

    it 'faithfully creates a transit service based on passed parameters' do
      attrs = attributes_for(:transit_service)
      params = {transit: attrs.merge(agency_id: agency.id), oversight:{oversight_agency_id: oversight_agency.id}}
      count = Transit.count

      post :create, params: params

      # test for the 302 status-code (redirect)
      expect(response).to have_http_status(302)

      # Confirm that a new service was created
      # expect(Transit.count).to eq(count + 1)

      # Confirm that the most recently created service matches the parameters sent
      @service = Transit.last
      attributes_match = attrs.all? { |att| attrs[att] == @service[att] }
      expect(attributes_match).to be true
    end

    it 'faithfully creates a paratransit service based on passed parameters' do
      attrs = attributes_for(:paratransit_service)
      params = {paratransit: attrs.merge(agency_id: agency.id), oversight:{oversight_agency_id: oversight_agency.id}}
      count = Paratransit.count

      post :create, params: params

      # test for the 302 status-code (redirect)
      expect(response).to have_http_status(302)

      # Confirm that a new service was created
      # expect(Paratransit.count).to eq(count + 1)

      # Confirm that the most recently created service matches the parameters sent
      @service = Paratransit.last
      attributes_match = attrs.all? { |att| attrs[att] == @service[att] }
      expect(attributes_match).to be true
    end

     it 'faithfully creates a taxi service based on passed parameters' do
       attrs = attributes_for(:taxi_service)
       attrs[:agency_id] = create(:agency).id
       params = {taxi: attrs,oversight:{oversight_agency_id: ''}}
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

    it 'faithfully creates an uber service based on passed parameters' do
       attrs = attributes_for(:uber_service)
       attrs[:agency_id] = create(:agency).id
       params = {uber: attrs,oversight:{oversight_agency_id: ''}}
       count = Uber.count

       post :create, params: params

       # test for the 302 status-code (redirect)
       expect(response).to have_http_status(302)

       # Confirm that a new service was created
       expect(Uber.count).to eq(count + 1)

       # Confirm that the most recently created service matches the parameters sent
       @service = Uber.last
       attributes_match = attrs.all? { |att| attrs[att] == @service[att] }
       expect(attributes_match).to be true
     end

    it 'faithfully creates a lyft service based on passed parameters' do
       attrs = attributes_for(:lyft_service)
       attrs[:agency_id] = create(:agency).id
       params = {lyft: attrs,oversight:{oversight_agency_id: ''}}
       count = Lyft.count

       post :create, params: params

       # test for the 302 status-code (redirect)
       expect(response).to have_http_status(302)

       # Confirm that a new service was created
       expect(Lyft.count).to eq(count + 1)

       # Confirm that the most recently created service matches the parameters sent
       @service = Lyft.last
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

    it "udates the updated_at attribute even if only child attributes changed" do 
      old_time = service.updated_at

      # Update Accommodations
      update_params = {
        id: service.id,
        service: {
          accommodation_ids: ["", wheelchair.id.to_s]
        }
      }
      put :update, params: update_params
      service.reload

      expect(service.updated_at).to be > old_time

    end

    it "updates a service's fare information" do
      # Hash with indifferent access containing sample params for various fare structures
      fare_details_params = {
        flat: { flat_base_fare: 5.0 },
        mileage: { mileage_base_fare: 2, mileage_rate: 1.0, trip_type: :taxi },
        taxi_fare_finder: { taxi_fare_finder_city: 'Boston' }
      }.with_indifferent_access

      # For each fare structure type, test service update
      [:flat, :mileage, :taxi_fare_finder].each do |fare_structure|
        old_fare_structure = service.fare_structure
        old_fare_details = service.fare_details
        update_params = {
          id: service.id,
          service: {
            fare_structure: fare_structure,
            fare_details: fare_details_params[fare_structure]
          }
        }
        put :update, params: update_params
        expect(response).to have_http_status(302) # should redirect on success
        service.reload
        expect(old_fare_structure).not_to eq(service.fare_structure) # should have changed fare_structure
        expect(old_fare_details).not_to eq(service.fare_details) # should have changed fare_details
        expect(service.fare_details).to eq(fare_details_params[fare_structure]) # fare_details should match params
      end
      
    end
    
  end
  
  context "while signed in as a staff" do
    
    before(:each) { sign_in staff }
    
    it "allows staff to see a list of their agency's services" do
      get :index
      expect(response).to be_success
      expect(assigns(:services).count).to eq(staff.staff_agency.services.count)
    end
    
    it "allows staff to see details for their agency's services" do
      get :show, params: {id: staff_service.id}
      expect(response).to be_success
    end
    
    it "prevents staff from viewing details of other agencies' services" do
      get :show, params: {id: other_service.id}
      expect(response).to have_http_status(:unauthorized)
    end
  
  end
  
  context "while signed in as a traveler" do
    
    before(:each) { sign_in traveler }
    
    it 'prevents travelers from viewing services list' do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
    
  end

  it 'queries taxis within specified regions' do
    other_start_area = Region.create(recipe: attributes_for(:region_2)[:recipe])
  
    # Create a taxi with a start_area
    start_area = Region.create(recipe: attributes_for(:region)[:recipe])
    created_taxi = Taxi.create(name: 'test taxi', agency: agency, start_area: start_area)
  
    # Get the taxis that have start_area equal to the start_area we created
    taxis_in_start_area = Taxi.where(start_area: start_area)
  
    # Expect the taxis_in_start_area to include the taxi we created
    expect(taxis_in_start_area).to include(created_taxi)
  
    # Get the taxis that have start_area equal to the other_start_area we created
    taxis_in_other_start_area = Taxi.where(start_area: other_start_area)
  
    # Expect the taxis_in_other_start_area not to include the taxi we created
    expect(taxis_in_other_start_area).not_to include(created_taxi)
  end
  
  it 'does not query taxi services from a different region' do
    start_area = Region.create(recipe: attributes_for(:region)[:recipe])
    different_region = Region.create(recipe: attributes_for(:region_2)[:recipe])
  
    # Create a taxi with a start_area
    created_taxi = Taxi.create(name: 'test taxi', agency: agency, start_area: start_area)
  
    # Get the taxis that have start_area equal to the different_region
    taxis_in_different_region = Taxi.where(start_area: different_region)
  
    # Expect the taxis_in_different_region not to include the taxi we created
    expect(taxis_in_different_region).not_to include(created_taxi)
  end  

  it 'does not query taxi services for rides starting in end_area' do
    start_area = Region.create(recipe: attributes_for(:region)[:recipe])
    end_area = Region.create(recipe: attributes_for(:region_2)[:recipe])
  
    # Create a taxi with a start_area and end_area
    created_taxi = Taxi.create(name: 'test taxi', agency: agency, start_area: start_area, end_area: end_area)
  
    # Get the taxis that have start_area equal to the end_area
    taxis_with_start_area_as_end_area = Taxi.where(start_area: end_area)
  
    # Expect the taxis_with_start_area_as_end_area not to include the taxi we created
    expect(taxis_with_start_area_as_end_area).not_to include(created_taxi)
  end  

end
