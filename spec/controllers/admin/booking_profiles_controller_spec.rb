require 'rails_helper'

RSpec.describe Admin::BookingProfilesController, type: :controller do
  let!(:superuser) { create(:user, :superuser) }
  let!(:oversight_admin) { create(:user, :oversight_admin) }
  let!(:normal_user) { create(:user) }
  let!(:booking_profiles) { create_list(:user_booking_profile, 5) }
  let!(:agency) { create(:transportation_agency, :with_services)}

  context 'GET #index' do
    context 'when the user is a superuser' do
      before do
        sign_in superuser
        get :index
      end

      it 'returns all UserBookingProfiles' do
        expect(assigns(:booking_profiles)).to eq UserBookingProfile.all
      end
    end

    context 'when the user is an oversight admin' do
      before do
        sign_in oversight_admin
        get :index
      end

      it 'returns UserBookingProfiles of the agencies underneath the oversight agency' do
        ag_ids = oversight_admin.staff_agency.agency_oversight_agency.pluck(:transportation_agency_id)
        expected_profiles = UserBookingProfile.joins(service: :agency).where('agencies.id': ag_ids)
        expect(assigns(:booking_profiles).sort_by(&:id)).to eq expected_profiles.sort_by(&:id)
      end         
    end

    context 'when the user is a normal user' do
      before do
        sign_in normal_user
        get :index
      end

      it 'returns only UserBookingProfiles of the specific user' do
        expect(assigns(:booking_profiles)).to eq normal_user.user_booking_profiles
      end
    end
  end
end
