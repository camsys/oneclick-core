require 'rails_helper'

RSpec.describe Api::V2::AgenciesController, type: :controller do
  let!(:agency_1) { create(:transportation_agency)}
  let!(:agency_2) { create(:transportation_agency)}
  let!(:agency_3) { create(:transportation_agency)}
  let!(:agency_4) { create(:partner_agency)}
  let!(:agency_5) { create(:partner_agency)}
  
  it "indexes all the agencies with all necessary attributes" do
    
    get :index
    
    expect(response).to be_success
    
    response_body = JSON.parse(response.body)
    agencies = response_body["data"]["agencies"]
        
    expect(agencies.count).to eq(Agency.all.count)
    
    # Expect each of the following attributes to be present in the JSON results
    [:id, :type, :name, :phone, :email, :url].each do |attr|
      expect(agencies.first[attr.to_s]).to be
    end
    
  end
  
  it "filters by agency type" do
    
    # First for Transportation Agencies
    get :index, params: {type: "transportation"}
    
    expect(response).to be_success
    
    response_body = JSON.parse(response.body)
    agencies = response_body["data"]["agencies"]
    
    expect(agencies.count).to eq(TransportationAgency.all.count)
    
    # Now for Partner Agencies
    get :index, params: {type: "partner"}
    
    expect(response).to be_success
    
    response_body = JSON.parse(response.body)
    agencies = response_body["data"]["agencies"]
    
    expect(agencies.count).to eq(PartnerAgency.all.count)
    
  end
  
end
