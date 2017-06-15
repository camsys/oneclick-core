require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do

  let!(:admin) { FactoryGirl.create :admin }
  let!(:non_admin) { FactoryGirl.create :user }
  let!(:another_admin) { FactoryGirl.create :another_admin }
  
  it 'gets a list of all the staff' do
    sign_in admin

    get :index

    # The response should be a re-direct
    expect(response).to be_success
  end

  it 'staff list cannot be viewed by a non-admin' do
    sign_in non_admin

    get :index

    # The response should be a re-direct
    expect(response).to have_http_status(302)
  end

  it 'updates a staff' do
    sign_in admin
    post :update, id: another_admin, user: {first_name: "new name", email: "new@email.com"}
    another_admin.reload
    expect(another_admin.first_name).to eq("new name")
    expect(another_admin.email).to eq("new@email.com")
  end

  it 'deletes a staff' do
    sign_in admin
    user_count = User.count 
    delete :destroy, id: another_admin
    expect(User.count).to eq(user_count - 1)
  end
  
end