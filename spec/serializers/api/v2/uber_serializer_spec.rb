require 'rails_helper'

RSpec.describe Api::V2::UberSerializer, type: :serializer do
  
  it_behaves_like "api_v2_service_serializer" do
    let(:service) { create(:uber_service) }
  end

end
