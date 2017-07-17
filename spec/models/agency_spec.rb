require 'rails_helper'

RSpec.describe Agency, type: :model do
  before(:each) do 
    create(:transportation_agency, :with_services)
    create(:partner_agency, :with_staff)
  end
  let(:transportation_agency) { TransportationAgency.last }
  let(:partner_agency) { PartnerAgency.last }
  let(:staff_agency) { PartnerAgency.last }
  let(:services_agency) { TransportationAgency.last }
  
  it { should respond_to :type, :name, :phone, :email, :url, :logo }
  it { should have_many(:services) }
  
  it_behaves_like "publishable"
  
  it "can be a TransportationAgency or a PartnerAgency" do
    expect(transportation_agency.is_a?(Agency)).to be true
    expect(transportation_agency.is_a?(TransportationAgency)).to be true
    expect(transportation_agency.transportation?).to be true
    expect(transportation_agency.is_a?(PartnerAgency)).to be false
    expect(transportation_agency.partner?).to be false
    
    expect(partner_agency.is_a?(Agency)).to be true
    expect(partner_agency.is_a?(PartnerAgency)).to be true
    expect(partner_agency.partner?).to be true
    expect(partner_agency.is_a?(TransportationAgency)).to be false
    expect(partner_agency.transportation?).to be false
  end
  
  it "can have staff" do
    expect(staff_agency.staff.count).to be > 0
    expect(staff_agency.staff.count).to eq(User.with_role(:staff, staff_agency).count)
    expect(staff_agency.staff.all? {|u| u.is_a?(User)}).to be true
  end
  
  it "can add staff" do
    staff_count = staff_agency.staff.count
    staff_agency.add_staff(create(:user))
    expect(staff_agency.staff.count).to eq(staff_count + 1)
  end
  
end
