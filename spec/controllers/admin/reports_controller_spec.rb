require 'rails_helper'

RSpec.describe Admin::ReportsController, type: :controller do

  let(:admin) { create(:admin) }
  let(:transportation_staff) { create :transportation_staff }
  let(:partner_staff) { create :partner_staff }
  let(:traveler) { create(:user) }
  
  let(:from_date) { (Date.today - 3.months) }
  let(:to_date) { Date.today }
  
  context "while signed in as an admin" do
    
    before(:each) { sign_in admin }
    
    ### DASHBOARDS ###
    
    describe 'dashboards' do
      
      describe 'planned trips dashboard' do
        # Create a bunch of monthly trips across a range of months
        before(:each) do
          (-5..2).map do |i|
            create(:trip, trip_time: Date.today + i.months)
          end
        end
                    
        # Filter params cover a daily range from 3 months ago to today.
        let(:date_filter_params) { { 
          from_date: from_date.to_s, 
          to_date: to_date.to_s, 
          grouping: :day 
        } }
      
        it 'redirects to dashboard page' do        
          params = { dashboard: { dashboard_name: 'Planned Trips' } }
          post :dashboard, params: params
          
          # The response should be a re-direct
          expect(response).to redirect_to('/admin/reports/planned_trips_dashboard')
        end
        
        it 'assigns appropriate filter params' do
          get :planned_trips_dashboard, params: date_filter_params
          expect(assigns(:from_date)).to eq(Date.parse(date_filter_params[:from_date]))
          expect(assigns(:to_date)).to eq(Date.parse(date_filter_params[:to_date]))
          expect(assigns(:grouping)).to eq(date_filter_params[:grouping].to_s)
        end
        
        it 'filters trips by date' do
          get :planned_trips_dashboard, params: date_filter_params
          
          # Date range from 3 months ago to today should contain 4 trips (includes fencepost days)
          expect(assigns(:trips).count).to eq(Trip.from_date(from_date).to_date(to_date).count)
        end

        it 'filters dashboard by partner agency' do
          partner_agency = partner_staff.agencies.first

          # Assign the last trip to the partner staff
          trip = Trip.last 
          trip.user = partner_staff 
          trip.save 

          # Check the CSV count without a filter
          params = {} 
          get :planned_trips_dashboard, params: params
          expect(assigns(:trips).count).to eq(Trip.all.count)

          # Check the CSV count with a filter
          params = { partner_agency: partner_agency.id }
          get :planned_trips_dashboard, params: params
          expect(assigns(:trips).count).to eq(1)
        end
        
      end
      
    end
    
    
    ### CSV TABLE DOWNLOADS ###

    describe 'csv table downloads' do
          
      describe 'users report' do
        before(:each) do
          create(:user, :with_trip_today)        
          create(:user, :needs_accommodation, :with_old_trip)
          create(:user, :eligible, :with_trip_today)
          create(:user, :eligible, :needs_accommodation)
          create(:guest, :with_trip_today)
          create(:guest, :needs_accommodation)
          create(:guest, :eligible)
        end
        
        it 'redirects to Users report download page' do
          params = {download_table: {table_name: 'Users'}}
          post :download_table, params: params

          # The response should be a re-direct
          expect(response).to redirect_to('/admin/reports/users_table.csv')
        end
        
        it 'downloads a Users report CSV file with a row for each registered user' do
          
          get :users_table, format: :csv
          expect(response).to be_success
          expect(response.body).to be_a(String)
          
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(User.registered.count)
        end
        
        it 'allows inclusion of guest users' do
          
          get :users_table, format: :csv, params: {
            include_guests: '1'
          }
          
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(User.count)
        end
        
        it 'filters by accommodation' do
          accommodations = [ Accommodation.first.id ]
          
          get :users_table, format: :csv, params: {
            accommodations: accommodations
          }
          
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(User.registered.with_accommodations(accommodations).count)
        end
        
        it 'filters by eligibility' do
          eligibilities = [ Eligibility.first.id ]
          
          get :users_table, format: :csv, params: {
            eligibilities: eligibilities
          }
          
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(User.registered.with_eligibilities(eligibilities).count)
        end
        
        it 'filters by trips planned during date range' do
          from_date = Date.today - 1.month
          to_date = Date.today + 1.month
          params = {
            user_active_from_date: from_date,
            user_active_to_date: to_date
          }
          
          get :users_table, format: :csv, params: params
          
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(
            User.registered.active_since(from_date).active_until(to_date).count
          )
        end

      end
      
      describe 'trips report' do
        
        before(:each) do
          create(:trip, :going_to_see_metallica, trip_time: Date.today - 5.months)
          create(:trip, trip_time: Date.today - 4.months, origin: create(:way_out_point))
          create(:trip, trip_time: Date.today - 3.months, origin: create(:way_out_point_2))
          create(:trip, :going_to_see_metallica, trip_time: Date.today - 2.months)
          create(:trip, trip_time: Date.today - 1.months, destination: create(:way_out_point))
          create(:trip, :going_to_see_metallica, trip_time: Date.today, destination: create(:way_out_point_2))
          create(:trip, trip_time: Date.today + 1.months)
          create(:trip, trip_time: Date.today + 2.months, origin: create(:way_out_point), destination: create(:way_out_point_2))
        end
        
        it 'redirects to Trips report download page' do
          params = {download_table: {table_name: 'Trips'}}
          post :download_table, params: params

          # The response should be a re-direct
          expect(response).to redirect_to('/admin/reports/trips_table.csv')
        end
        
        it 'downloads a Trips report CSV file with a row for each trip' do
          
          get :trips_table, format: :csv
          expect(response).to be_success
          expect(response.body).to be_a(String)
          
          response_body = CSV.parse(response.body)
          expect(response_body.length).to eq(Trip.count + 1)
        end
        
        it 'filters by date range' do
          params = {
            trip_time_from_date: from_date.to_s, 
            trip_time_to_date: to_date.to_s
          }
    
          get :trips_table, format: :csv, params: params
          
          # Date range from 3 months ago to today should contain 4 trips (includes fencepost days)
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(
            Trip.from_date(from_date).to_date(to_date).count
          )
        end
        
        it 'filters by purpose' do
          purpose_ids = [Purpose.find_by(code: "metallica_concert").id]
          params = {
            purposes: purpose_ids
          }
          
          get :trips_table, format: :csv, params: params
          
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(Trip.with_purpose(purpose_ids).count)
        end
        
        it 'filters by origin and destination' do
          origin_recipe = GeoKitchen::GeoRecipe.new([Zipcode.find_by(name: "02139").to_geo]).to_json
          destination_recipe = GeoKitchen::GeoRecipe.new([Zipcode.find_by(name: "02140").to_geo]).to_json
          params = {
            trip_origin_recipe: origin_recipe,
            trip_destination_recipe: destination_recipe
          }
          
          get :trips_table, format: :csv, params: params
          
          origin_geom = Region.build(recipe: origin_recipe).geom
          destination_geom = Region.build(recipe: destination_recipe).geom
          
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(Trip.origin_in(origin_geom).destination_in(destination_geom).count)
        end

        it 'filters by partner agency' do
          partner_agency = partner_staff.agencies.first

          # Assign the last trip to the partner staff
          trip = Trip.last 
          trip.user = partner_staff 
          trip.save 

          # Check the CSV count without a filter
          params = {} 
          get :trips_table, format: :csv, params: params
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(Trip.all.count)

          # Check the CSV count with a filter
          params = { partner_agency: partner_agency.id }
          get :trips_table, format: :csv, params: params
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(1)
        end
        
      end
    
      describe 'services report' do
        before(:each) do
          create(:paratransit_service, :strict, :medical_only)
          create(:paratransit_service, :accommodating, :strict)
          create(:paratransit_service, :accommodating, :medical_only)
          create(:paratransit_service, :accommodating, :strict)
          create(:paratransit_service, :accommodating)
          create(:transit_service)
          create(:taxi_service)
          create(:uber_service)
          create(:lyft_service)
        end
        
        it 'redirects to Services report download page' do
          params = {download_table: {table_name: 'Services'}}
          post :download_table, params: params

          # The response should be a re-direct
          expect(response).to redirect_to('/admin/reports/services_table.csv')
        end

        it 'downloads a Services report CSV file with a row for each user' do        
          get :services_table, format: :csv
          expect(response).to be_success
          expect(response.body).to be_a(String)
          
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(Service.count)
        end
        
        it 'filters by service type' do
          type = "Paratransit"
          params = { service_type: type }
          get :services_table, format: :csv, params: params
          
          response_body = CSV.parse(response.body)        
          expect(response_body.length - 1).to eq(Service.where(type: type).count)
        end
        
        it 'filters by accommodation' do
          accommodations = [ Accommodation.first.id ]
          params = { accommodations: accommodations }
      
          get :services_table, format: :csv, params: params
          
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(Service.with_accommodations(accommodations).count)
        end
        
        it 'filters by eligibility' do
          eligibilities = [ Eligibility.first.id ]
          params = { eligibilities: eligibilities }
      
          get :services_table, format: :csv, params: params
          
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(Service.with_eligibilities(eligibilities).count)
        end
        
        it 'filters by purpose' do
          purposes = [ Purpose.first.id ]
          params = { purposes: purposes }
      
          get :services_table, format: :csv, params: params
          
          response_body = CSV.parse(response.body)
          expect(response_body.length - 1).to eq(Service.with_purposes(purposes).count)
        end
        
      end

    end
    
  end
  
  context "while signed in as a partner staff" do
    
    before(:each) { sign_in partner_staff }
    
    it "allows partner staff to view reports" do
      get :index
      
      expect(response).to be_success
      expect(assigns(:download_tables)).to eq(Admin::ReportsController::DOWNLOAD_TABLES)
      expect(assigns(:dashboards)).to eq(Admin::ReportsController::DASHBOARDS)
      
    end
  
  end
  
  context "while signed in as a transportation staff" do
    
    before(:each) { sign_in transportation_staff }
    
    it "prevents transportation staff from viewing reports" do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
  
  end
  
  context "while signed in as a traveler" do
    
    before(:each) { sign_in traveler }
    
    it "prevents travelers from viewing reports" do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
    
  end
  

end
