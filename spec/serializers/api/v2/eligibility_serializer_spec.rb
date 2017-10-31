require 'rails_helper'

RSpec.describe Api::V2::EligibilitySerializer, type: :serializer do
  
  let(:eligibility) { create(:eligibility) }
  let(:user_with_elig) { create(:user) }
  let(:user_no_elig) { create(:user) }
  
  it_behaves_like "characteristic_serializer" do
    let(:characteristic) { create(:eligibility, :with_translations) }
  end
  
  it "serializes value based on whether or not user has eligibility" do
    user_with_elig.eligibilities << eligibility
    user_with_elig_hash = Api::V2::EligibilitySerializer.new(eligibility, scope: {locale: "en", user: user_with_elig}).to_h
    user_no_elig_hash = Api::V2::EligibilitySerializer.new(eligibility, scope: {locale: "en", user: user_no_elig}).to_h

    expect(user_with_elig_hash[:value]).to eq(true)
    expect(user_no_elig_hash[:value]).to eq(false)    
  end
  
end
