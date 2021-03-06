require 'rails_helper'

RSpec.describe Api::V2::PurposeSerializer, type: :serializer do
  
  it_behaves_like "api_v2_characteristic_serializer" do
    let(:characteristic) { create(:purpose, :with_translations) }
  end
  
end
