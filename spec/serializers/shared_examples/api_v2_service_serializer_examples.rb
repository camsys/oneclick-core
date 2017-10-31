RSpec.shared_examples "api_v2_service_serializer" do
  
  ###
  # NOTE: Set service variable in the it_behaves_like block
  ###
  
  # Make a serialization for each locale
  let(:serializations) do
    I18n.available_locales.map do |l|
      [l, described_class.new(service, scope: {locale: l}).to_h]
    end.to_h
  end
  
  let(:basic_attributes) do
    [ 
      :id, 
      :name, 
      :type, 
      :url, 
      :email, 
      :phone, 
      :formatted_phone,
      :rating, 
      :ratings_count
    ]
  end
  
  let(:array_attributes) do
    [
      :schedules,
      :accommodations,
      :eligibilities,
      :purposes  
    ]
  end
  
  it "faithfully serializes an service, by locale" do
    serializations.each do |loc, service_hash|
      
      # Check the basic attributes
      basic_attributes.each do |attr|
        expect(service_hash[attr]).to eq(service.send(attr))
      end
      
      array_attributes.each do |attr|
        expect(service_hash[attr]).to be_a Array
        expect(service_hash[attr].count).to eq service.send(attr).count
      end

      # Check custom attributes
      expect(service_hash[:logo]).to eq(service.full_logo_url)
      expect(service_hash[:description]).to eq(service.description(loc))
      
    end
  end
  
end
