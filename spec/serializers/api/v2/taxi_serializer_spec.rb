require 'rails_helper'

RSpec.describe Api::V2::TaxiSerializer, type: :serializer do
  
  it_behaves_like "api_v2_service_serializer" do
    let(:service) { create(:taxi_service) }
  end

end
