require 'rails_helper'

RSpec.describe Admin::PurposesController, type: :controller do

  let(:superuser) { create(:superuser) }
  let(:staff) { create(:staff_user) }
  let(:traveler) { create(:user) }
  let(:metallica_concert) { FactoryBot.create :metallica_concert }
  
  context "while signed in as a superuser" do
    
    before(:each) { sign_in superuser }
    
    it 'gets a list of all purposes' do
      get :index
      expect(response).to be_success
    end

    it 'updates the translations' do
      params = {id: metallica_concert.id, purpose: {en_name: 'new name', en_note: 'new note', en_question: 'new question'}}

      patch :update, params: params, format: :html

      expect(metallica_concert.name).to eq('new name')
      expect(metallica_concert.note).to eq('new note')
      expect(metallica_concert.question).to eq('new question')
    end

    it 'creates a purpose' do      
      purpose_count = Purpose.count
      
      params = {purpose: {code: 'Test DeLEte& purpose22', name: 'Test', agency_id: create(:transportation_agency).id}}
      post :create, params: params, format: :js
      
      # Confirm that the variable was set
      expect(Purpose.count).to eq(purpose_count + 1)

      # Confirm that the code was set to snake case
      expect(Purpose.last.code).to eq('test_delete_purpose22')
    end
    
    it 'destroys a purpose' do
      create(:purpose)
      purpose_count = Purpose.count
      purpose_id = Purpose.last.id
      delete :destroy, params: {id: purpose_id}, format: :js
      
      # Expect purpose count to be down
      expect(Purpose.count).to eq(purpose_count - 1)
      
      # Purpose should be gone
      expect(Purpose.find_by(id: purpose_id)).to be nil
    end
    
  end
  
  context "while signed in as a staff" do
    
    before(:each) { sign_in staff }
    
    it 'it prevents staff from viewing the list of purposes' do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
  
  end
  
  context "while signed in as a traveler" do
    
    before(:each) { sign_in traveler }
    
    it 'it prevents travelers from viewing the list of purposes' do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
    
  end

end
