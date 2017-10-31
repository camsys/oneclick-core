require 'rails_helper'

RSpec.describe Api::V2::TransportationAgencySerializer, type: :serializer do
  
  it_behaves_like "api_v2_agency_serializer" do
    let(:agency) { create(:transportation_agency) }
  end

end
