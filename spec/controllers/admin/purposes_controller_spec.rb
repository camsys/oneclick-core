require 'rails_helper'

RSpec.describe Admin::PurposesController, type: :controller do 

  let!(:admin) { FactoryGirl.create :admin }
  let!(:non_admin) { FactoryGirl.create :user }
  let(:metallica_concert) { FactoryGirl.create :metallica_concert }
  
  it 'gets a list of all purposes' do
    sign_in admin

    get :index

    # The response should be a re-direct
    expect(response).to be_success
  end

  it 'it prevents non-admins from viewing the list of purposes' do
    sign_in non_admin

    get :index

    # The response should be a re-direct
    expect(response).to have_http_status(302)
  end

  it 'creates a new purpose' do
    # Clean up any old purposes
    Purpose.delete_all

    sign_in admin
    params = {purpose: {code: 'Test purPOSE'}}
    post :create, params: params, format: :js

    # test for the 302 status-code (redirect)
    expect(response).to have_http_status(302)

    # Confirm that the variable was set
    expect(Purpose.count).to eq(1)

    # Confirm that the code was set to snake case
    expect(Purpose.last.code).to eq('test_purpose')

  end

  it 'updates the translations' do
    sign_in admin
    params = {id: metallica_concert.id, purpose: {en_name: 'new name', en_note: 'new note', en_question: 'new question'}}

    patch :update, params: params, format: :html

    expect(metallica_concert.name).to eq('new name')
    expect(metallica_concert.note).to eq('new note')
    expect(metallica_concert.question).to eq('new question')

  end

  it 'creates a purpose' do
    sign_in admin
    
    purpose_count = Purpose.count
    
    params = {purpose: {code: 'Test DeLEte& purpose22'}}
    post :create, params: params, format: :js
    
    # Confirm that the variable was set
    expect(Purpose.count).to eq(purpose_count + 1)

    # Confirm that the code was set to snake case
    expect(Purpose.last.code).to eq('test_delete_purpose22')
    
  end
  
  it 'destroys a purpose' do
    sign_in admin
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
