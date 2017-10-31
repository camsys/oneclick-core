require 'rails_helper'

RSpec.describe Api::V2::AccommodationSerializer, type: :serializer do
  
  let(:accommodation) { create(:accommodation) }
  let(:user_with_acc) { create(:user) }
  let(:user_no_acc) { create(:user) }
  
  it_behaves_like "api_v2_characteristic_serializer" do
    let(:characteristic) { create(:accommodation, :with_translations) }
  end
  
  it "serializes value based on whether or not user has accommodation" do
    user_with_acc.accommodations << accommodation
    user_with_acc_hash = Api::V2::AccommodationSerializer.new(accommodation, scope: {locale: "en", user: user_with_acc}).to_h
    user_no_acc_hash = Api::V2::AccommodationSerializer.new(accommodation, scope: {locale: "en", user: user_no_acc}).to_h

    expect(user_with_acc_hash[:value]).to eq(true)
    expect(user_no_acc_hash[:value]).to eq(false)    
  end
  
end
