require 'rails_helper'

RSpec.describe Admin::AccommodationsController, type: :controller do

  let(:admin) { create(:admin) }
  let(:staff) { create(:staff_user) }
  let(:traveler) { create(:user) }
  let(:jacuzzi) { create(:jacuzzi) }
  
  context "while signed in as admin" do
    
    before(:each) { sign_in admin }
    
    it 'gets a list of all accommodations' do    
      get :index
      expect(response).to be_success
    end
    
    it 'creates a new accommodation' do
      count = Accommodation.count
      post :create, params: { accommodation: {code: 'Test accommodAtion'} }, format: :js
    
      # test for the 302 status-code (redirect)
      expect(response).to have_http_status(302)
    
      # Confirm that the variable was set
      expect(Accommodation.count).to eq(count + 1)
    
      # Confirm that the code was set to snake case
      expect(Accommodation.last.code).to eq('test_accommodation')
    end
    
    it 'updates the translations' do
      params = {id: jacuzzi.id, accommodation: {en_name: 'new name', en_note: 'new note', en_question: 'new question'}}
    
      patch :update, params: params, format: :html
      
      expect(jacuzzi.name).to eq('new name')
      expect(jacuzzi.note).to eq('new note')
      expect(jacuzzi.question).to eq('new question')
    
    end
    
    it 'creates and destroys an accommodation' do
      params = {accommodation: {code: 'Test DeLEte& accommodation22'}}
      count = Accommodation.count
      post :create, params: params, format: :js
    
      # Confirm that the variable was set
      expect(Accommodation.count).to eq(count + 1)
    
      # Confirm that the code was set to snake case
      expect(Accommodation.last.code).to eq('test_delete_accommodation22')
    
      params = {id: Accommodation.last.id}
      delete :destroy, params: params, format: :js
    
      # Confirm that there are no eligibilities
      expect(Accommodation.count).to eq(count)
    end
    
  end
  
  context "while signed in as a staff" do
    
    before(:each) { sign_in staff }
    
    it 'prevents access to accommodations page' do    
      get :index
      expect(response).to have_http_status(302)
    end
    
  end
  
  context "while signed in as a traveler" do
    
    before(:each) { sign_in traveler }
    
    it 'prevents access to accommodations page' do    
      get :index
      expect(response).to have_http_status(302)
    end
    
  end

end
