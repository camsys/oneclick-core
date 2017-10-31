RSpec.shared_examples "api_v2_agency_serializer" do
  
  ###
  # NOTE: Set agency variable in the it_behaves_like block
  ###
  
  # Make a serialization for each locale
  let(:serializations) do
    I18n.available_locales.map do |l|
      [l, described_class.new(agency, scope: {locale: l}).to_h]
    end.to_h
  end  
  
  it "faithfully serializes an agency, by locale" do
    serializations.each do |loc, agency_hash|
      
      # Check the basic attributes
      [:id, :name, :type, :phone, :formatted_phone, :email, :url].each do |attr|
        expect(agency_hash[attr]).to eq(agency.send(attr))
      end
      
      # Check custom attributes
      expect(agency_hash[:logo]).to eq(agency.full_logo_url)
      expect(agency_hash[:description]).to eq(agency.description(loc))
      
    end
  end
  
end
