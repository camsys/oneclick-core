require 'rails_helper'

RSpec.describe Api::V2::PartnerAgencySerializer, type: :serializer do
  
  it_behaves_like "api_v2_agency_serializer" do
    let(:agency) { create(:partner_agency) }
  end

end
