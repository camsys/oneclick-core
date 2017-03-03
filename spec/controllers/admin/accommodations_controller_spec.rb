require 'rails_helper'

RSpec.describe Admin::AccommodationsController, type: :controller do

  let!(:admin) { FactoryGirl.create :admin }
  let!(:non_admin) { FactoryGirl.create :user }

  it 'gets a list of all accommodations' do
    sign_in admin

    get :index

    # The response should be a re-direct
    expect(response).to be_success
  end

  it 'it prevents non-admins from viewing the list of accommodaitons' do
    sign_in non_admin

    get :index

    # The response should be a re-direct
    expect(response).to have_http_status(302)
  end

  it 'creates a new accommodation' do
    sign_in admin
    params = {accommodation: {code: 'Test accommodAtion'}}
    count = Accommodation.count
    post :create, params: params, format: :js

    # test for the 302 status-code (redirect)
    expect(response).to have_http_status(302)

    # Confirm that the variable was set
    expect(Accommodation.count).to eq(count + 1)

    # Confirm that the code was set to snake case
    expect(Accommodation.last.code).to eq('test_accommodation')

  end

  it 'creates and destroys an accommodation' do
    sign_in admin
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
