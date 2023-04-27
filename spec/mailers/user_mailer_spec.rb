require "rails_helper"

RSpec.describe UserMailer, type: :mailer do

  let(:agency) { create(:partner_agency, :with_staff) }
  let(:admin) { create(:transportation_admin) }
  let(:user) { create(:user) }
  let(:trip) { create(:trip, user: user) }
  let(:itinerary) { create(:transit_itinerary, trip: trip) }

  it { should respond_to :agency_setup_reminder}

  it "sends an agency setup reminder to all agency staff, agency email, and system admins" do
    email = UserMailer.agency_setup_reminder(agency)
    to_addresses = agency.staff.pluck(:email) + [admin.email] + [agency.email] 

    expect(email.to - to_addresses).to eq([])
  end

  it "includes correct header in user trip email" do
    email = UserMailer.user_trip_email([user.email], trip, itinerary)  
    expect(email.body.encoded).to include(I18n.t('api_v1.emails.user_trip_header.automated_message'))
    expect(email.body.encoded).to include(I18n.t('api_v1.emails.user_trip_header.opener'))
  end

end
