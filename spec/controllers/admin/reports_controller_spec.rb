require 'rails_helper'

RSpec.describe Admin::ReportsController, type: :controller do

  let!(:admin) { create(:admin) }  
  before(:each) { sign_in admin }
  
  # Filter params cover a daily range from 3 months ago to today.
  let(:filter_params) { { 
    from_date: (Date.today - 3.months).to_s, 
    to_date: Date.today.to_s, 
    grouping: :day 
  } }
  
  # Create a bunch of monthly trips across a range of months
  before(:each) do
    (-5..2).map do |i|
      create(:trip, trip_time: Date.today + i.months)
    end
  end
  
  
  
  ### DASHBOARDS ###
  
  describe 'dashboards' do
    
    describe 'planned trips dashboard' do
    
      it 'redirects to dashboard page' do
        params = { dashboard: { dashboard_name: 'Planned Trips' } }
        post :dashboard, params: params
        
        # The response should be a re-direct
        expect(response).to redirect_to('/admin/reports/planned_trips_dashboard')
      end
      
      it 'assigns appropriate filter params' do 
        get :planned_trips_dashboard, params: filter_params
        expect(assigns(:from_date)).to eq(Date.parse(filter_params[:from_date]))
        expect(assigns(:to_date)).to eq(Date.parse(filter_params[:to_date]))
        expect(assigns(:grouping)).to eq(filter_params[:grouping].to_s)
      end
      
      it 'filters trips by date' do
        get :planned_trips_dashboard, params: filter_params
        
        # Date range from 3 months ago to today should contain 4 trips (includes fencepost days)
        expect(assigns(:trips).count).to eq(4)
      end
      
    end
    
  end
  
  
  ### CSV TABLE DOWNLOADS ###

  describe 'csv table downloads' do
        
    describe 'users report' do
      
      it 'redirects to Users report download page' do
        params = {download_table: {table_name: 'Users'}}
        post :download_table, params: params

        # The response should be a re-direct
        expect(response).to redirect_to('/admin/reports/users_table.csv')
      end
      
      it 'downloads a Users report CSV file with a row for each user' do
        5.times { create(:user) }
        
        get :users_table, format: :csv
        expect(response).to be_success
        expect(response.body).to be_a(String)
        
        response_body = CSV.parse(response.body)
        expect(response_body.length).to eq(User.count + 1)
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
  
        get :trips_table, format: :csv, params: filter_params
        
        # Date range from 3 months ago to today should contain 4 trips (includes fencepost days)
        response_body = CSV.parse(response.body)
        expect(response_body.length).to eq(4 + 1)
      
      end
      
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
      
    end
    
    

  end
  
end
