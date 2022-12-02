require 'rails_helper'

RSpec.describe Admin::EligibilitiesController, type: :controller do

  let(:superuser) { create(:superuser) }
  let(:staff) { create(:staff_user) }
  let(:traveler) { create(:user) }
  let(:veteran) { create(:veteran) }
  
  context "while signed in as a superuser" do
    
    before(:each) { sign_in superuser }
    
    it 'gets a list of all eligibilities' do
      get :index
      expect(response).to be_success
    end

    it 'creates a new eligibility' do
      params = {eligibility: {code: 'Test eligibility', rank: 100}}
      count = Eligibility.count
      post :create, params: params, format: :js

      # test for the 302 status-code (redirect)
      expect(response).to have_http_status(302)

      # Confirm that the variable was set
      expect(Eligibility.count).to eq(count + 1)

      # Confirm that the code was set to snake case
      expect(Eligibility.last.code).to eq('test_eligibility')

    end

    it 'updates the translations' do
      params = {id: veteran.id, eligibility: {en_name: 'new name', en_note: 'new note', en_question: 'new question'}}

      patch :update, params: params, format: :html

      expect(veteran.name).to eq('new name')
      expect(veteran.note).to eq('new note')
      expect(veteran.question).to eq('new question')
    end

    it 'creates and destroys an eligibility' do
      params = {eligibility: {code: 'Test DeLEte& eligibility22'}}
      count = Eligibility.count
      post :create, params: params, format: :js

      # Confirm that the variable was set
      expect(Eligibility.count).to eq(count + 1)

      # Confirm that the code was set to snake case
      expect(Eligibility.last.code).to eq('test_delete_eligibility22')

      params = {id: Eligibility.last.id}
      delete :destroy, params: params, format: :js

      # Confirm that there are no eligibilities
      expect(Eligibility.count).to eq(count)
    end
    
  end
  
  context "while signed in as a staff" do
    
    before(:each) { sign_in staff }

    it 'it prevents staff from viewing the list of eligibilities' do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
  
  end
  
  context "while signed in as a traveler" do
    
    before(:each) { sign_in traveler }

    it 'it prevents travelers from viewing the list of eligibilities' do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
    
  end

end
