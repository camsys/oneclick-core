require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:agency) { create(:partner_agency, :with_staff) }
  let(:admin) { create(:admin) }
  
  it { should respond_to :agency_setup_reminder}
  
  it "sends an agency setup reminder to all agency staff, agency email, and system admins" do
    email = UserMailer.agency_setup_reminder(agency)
    to_addresses = agency.staff.pluck(:email) + [admin.email] + [agency.email] 
    
    expect(email.to - to_addresses).to eq([])
  end
end
