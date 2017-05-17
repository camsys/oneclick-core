require 'rails_helper'

RSpec.describe Admin::ReportsController, type: :controller do

  let!(:admin) { create(:admin) }

  describe 'csv downloads' do
    
    before(:each) { sign_in admin }
    
    it 'redirects to Users report download page' do
      params = {download_csv: {table_name: 'Users'}}
      post :download_csv, params: params

      # The response should be a re-direct
      expect(response).to redirect_to('/admin/reports/users_table.csv')
    end
    
    it 'redirects to Trips report download page' do
      params = {download_csv: {table_name: 'Trips'}}
      post :download_csv, params: params

      # The response should be a re-direct
      expect(response).to redirect_to('/admin/reports/trips_table.csv')
    end
    
    it 'redirects to Services report download page' do
      params = {download_csv: {table_name: 'Services'}}
      post :download_csv, params: params

      # The response should be a re-direct
      expect(response).to redirect_to('/admin/reports/services_table.csv')
    end
    
    it 'downloads a Users report CSV file with a row for each user' do
      5.times { create(:user) }
      
      get :users, format: :csv
      expect(response).to be_success
      expect(response.body).to be_a(String)
      
      response_body = CSV.parse(response.body)
      expect(response_body.length).to eq(User.count + 1)
    end
    
    it 'downloads a Trips report CSV file with a row for each trip' do
      4.times { create(:trip) }
      
      get :trips, format: :csv
      expect(response).to be_success
      expect(response.body).to be_a(String)
      
      response_body = CSV.parse(response.body)
      expect(response_body.length).to eq(Trip.count + 1)
    end
    
    it 'downloads a Services report CSV file with a row for each user' do
      3.times { create(:service) }
      
      get :services, format: :csv
      expect(response).to be_success
      expect(response.body).to be_a(String)
      
      response_body = CSV.parse(response.body)
      expect(response_body.length).to eq(Service.count + 1)
    end

  end
  
end
