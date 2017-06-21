require 'rails_helper'

RSpec.describe Admin::ReportsController, type: :controller do

  let!(:admin) { create(:admin) }  
  before(:each) { sign_in admin }
  
  # Create a bunch of monthly trips across a range of months
  before(:each) do
    (-5..2).map do |i|
      create(:trip, trip_time: Date.today + i.months)
    end
  end
  
  let(:from_date) { (Date.today - 3.months) }
  let(:to_date) { Date.today }
  
  
  ### DASHBOARDS ###
  
  describe 'dashboards' do
    
    describe 'planned trips dashboard' do
                  
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
      
    end
    
  end
  
  
  ### CSV TABLE DOWNLOADS ###

  describe 'csv table downloads' do
        
    describe 'users report' do
      before(:each) do
        u1 = create(:user, :with_trip_today)        
        u2 = create(:user, :needs_accommodation, :with_old_trip)
        u3 = create(:user, :eligible, :with_trip_today)
        u4 = create(:user, :eligible, :needs_accommodation)
        gu1 = create(:guest, :with_trip_today)
        gu2 = create(:guest, :needs_accommodation)
        gu3 = create(:guest, :eligible)
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
      
      pending 'filters by purpose'
      
      pending 'filters by origin and destination'
      
    end
  
    describe 'services report' do
      
      it 'redirects to Services report download page' do
        params = {download_table: {table_name: 'Services'}}
        post :download_table, params: params

        # The response should be a re-direct
        expect(response).to redirect_to('/admin/reports/services_table.csv')
      end

      it 'downloads a Services report CSV file with a row for each user' do
        3.times { create(:service) }
        
        get :services_table, format: :csv
        expect(response).to be_success
        expect(response.body).to be_a(String)
        
        response_body = CSV.parse(response.body)
        expect(response_body.length).to eq(Service.count + 1)
      end
      
      pending 'filters by service type'
      
      pending 'filters by accommodation'
      
      pending 'filters by eligibility'
      
      pending 'filters by purpose'
      
    end
    
    

  end
  
end
