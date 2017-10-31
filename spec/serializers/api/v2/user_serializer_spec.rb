require 'rails_helper'

RSpec.describe Api::V2::UserSerializer, type: :serializer do
  
  let(:user) { create(:english_speaker, 
                      :needs_accommodation, 
                      :eligible, 
                      preferred_trip_types: ["paratransit", "bicycle"]) }
  let(:serialization) { Api::V2::UserSerializer.new(user, scope: { locale: user.preferred_locale.name }).to_h }
  
  let(:basic_attributes) {
    [
      :first_name, 
      :last_name, 
      :email
    ]
  }
  
  it "faithfully serializes a user" do
    
    basic_attributes.each do |attr|
      expect(serialization[attr]).to eq(user.send(attr))
    end
    
    expect(serialization[:accommodations].count).to eq(user.accommodations.count)
    expect(serialization[:eligibilities].count).to eq(user.eligibilities.count)
    expect(serialization[:trip_types].select {|tt| tt[:value]}.count)
      .to eq(user.preferred_trip_types.count)
    expect(serialization[:preferred_locale]).to eq(user.preferred_locale.name)
    
  end

end
