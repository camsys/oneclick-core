require 'rails_helper'

RSpec.describe Admin::TravelPatternsController, type: :controller do
  let(:agency_type) { AgencyType.create!(name: 'Type') }
  let(:pennDOT) { OversightAgency.create!(name: 'PennDOT', agency_type: agency_type) }
  let(:other_agency) { OversightAgency.create!(name: 'OtherAgency', agency_type: agency_type) }
  let(:pennDOT_agency) { TransportationAgency.create!(name: 'PennDOTAgency', agency_type: agency_type) }
  let(:other_agency_agency) { TransportationAgency.create!(name: 'OtherOtherAgency', agency_type: agency_type) }
  let!(:pennDOT_oversight_agency) { AgencyOversightAgency.create!(transportation_agency: pennDOT_agency, oversight_agency: pennDOT) }
  let!(:other_oversight_agency) { AgencyOversightAgency.create!(transportation_agency: other_agency_agency, oversight_agency: other_agency) }
  let(:admin_role) { Role.create!(name: 'admin') }

  let(:pennDOT_admin) do
    user = User.create!(email: 'admin@penndot.com', password: 'password1', password_confirmation: 'password1', current_agency: pennDOT_agency)
    user.add_role :admin
    user
  end

  let(:other_agency_admin) do
    user = User.create!(email: 'admin@other.com', password: 'password1', password_confirmation: 'password1', current_agency: other_agency_agency)
    user.add_role :admin
    user
  end

  describe "GET #booking_profiles" do
    context "when the user is not an admin for Penn DOT" do
      before do
        sign_in other_agency_admin
      end

      it "redirects to some other path" do
        get :booking_profiles
        expect(response).to redirect_to(root_path)
      end
    end

    context "when the user is an admin for PennDOT" do
      before do
        sign_in pennDOT_admin
      end

      it "does not redirect" do
        get :booking_profiles
        expect(response).not_to redirect_to(root_path)
      end
    end
  end
end
