require 'rails_helper'

RSpec.describe Admin::EligibilitiesController, type: :controller do

  let!(:admin) { FactoryGirl.create :admin }
  let!(:non_admin) { FactoryGirl.create :user }

  it 'gets a list of all eligibilities' do
    sign_in admin

    get :index

    # The response should be a re-direct
    expect(response).to be_success
  end

  it 'it prevents non-admins from viewing the list of eligibilities' do
    sign_in non_admin

    get :index

    # The response should be a re-direct
    expect(response).to have_http_status(302)
  end

  it 'creates a new eligibility' do
    sign_in admin
    params = {eligibility: {code: 'Test eligibility'}}
    count = Eligibility.count
    post :create, params: params, format: :js

    # test for the 302 status-code (redirect)
    expect(response).to have_http_status(302)

    # Confirm that the variable was set
    expect(Eligibility.count).to eq(count + 1)

    # Confirm that the code was set to snake case
    expect(Eligibility.last.code).to eq('test_eligibility')

  end

  it 'creates and destroys an eligibility' do
    sign_in admin
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
