require 'rails_helper'

RSpec.describe Admin::PurposesController, type: :controller do 

  let!(:admin) { FactoryGirl.create :admin }
  let!(:non_admin) { FactoryGirl.create :user }
  
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

  it 'creates and destroys a purpose' do 
    # Clean up any old purposes
    Purpose.delete_all
    
    sign_in admin
    params = {purpose: {code: 'Test DeLEte& purpose22'}}
    post :create, params: params, format: :js

    # Confirm that the variable was set
    expect(Purpose.count).to eq(1)

    # Confirm that the code was set to snake case
    expect(Purpose.last.code).to eq('test_delete_purpose22')

    params = {id: Purpose.last.id}
    delete :destroy, params: params, format: :js 

    # Confirm that there are no eligibilities
    expect(Purpose.count).to eq(0)
  end

end