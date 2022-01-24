require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do

  let(:agency) { create(:transportation_agency) }

  let!(:superuser) { create(:superuser) }
  let!(:staff) { create(:staff_user, staff_agency: agency) }
  let!(:fellow_staff) { create(:staff_user, staff_agency: agency) }
  let!(:other_staff) { create(:staff_user) }
  let!(:traveler) { create(:user) }
  
  context "while signed in as a superuser" do
    
    before(:each) { sign_in superuser }
    
    it 'gets a list of all the staff and admins' do
      get :staff
      expect(response).to be_success
      expect(assigns(:staff)&.count).to eq(User.any_role.count)
    end

    it 'updates a staff' do
      post :update, params: { id: staff.id, user: { first_name: "new name", email: "new@email.com", roles: 'staff', staff_agency: staff.staff_agency.id } }
      staff.reload
      expect(staff.first_name).to eq("new name")
      expect(staff.email).to eq("new@email.com")
    end

    it 'deletes a staff' do
      staff_count = User.staff.count 
      delete :destroy, params: { id: staff.id }
      expect(User.staff.count).to eq(staff_count - 1)
    end
    
    it 'can change staff agency' do
      new_agency = create(:transportation_agency)
      post :update, params: { id: other_staff.id, user: { staff_agency: new_agency.id, roles: 'staff' } }
      other_staff.reload
      expect(other_staff.staff_agency.id).to eq(new_agency.id)      
    end
    
    it 'can manage admin privileges' do
      expect(other_staff.admin?).to be false
      post :update, params: { id: other_staff.id, user: { roles:'admin'} }
      other_staff.reload
      expect(other_staff.admin?).to be true
    end
    
    it 'creates a staff user' do
      user_count = User.count
      post :create, params: { user: attributes_for(:user).merge({ staff_agency: agency.id, roles:'staff' }) }
      expect(User.count).to eq(user_count + 1)
      expect(User.last.staff?).to be true
    end
    
  end
  
  context "while signed in as a staff" do
    
    before(:each) { sign_in staff }
    
    it 'gets a list of all the staff for the same agency' do
      get :staff
      expect(response).to be_success
      expect(assigns(:staff).count).to eq(staff.fellow_staff.count)
    end
    
    it 'cannot change staff agency or manage admin privileges' do
      new_agency = create(:transportation_agency)
      post :update, params: { id: fellow_staff.id, user: { staff_agency: new_agency.id, role: 'admin' } }
      fellow_staff.reload
      expect(fellow_staff.staff_agency.id).not_to eq(new_agency.id)
      expect(fellow_staff.admin?).to be false
    end
      
  end
  
  context "while signed in as a traveler" do
    
    before(:each) { sign_in traveler }
    
    it 'prevents travelers from viewing staff list' do
      get :staff
      expect(response).to have_http_status(:unauthorized)
    end
    
  end
  
end
