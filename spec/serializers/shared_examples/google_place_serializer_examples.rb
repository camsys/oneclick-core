RSpec.shared_examples "google_place_serializer" do
  
  ###
  # NOTE: Set google_place variable in the it_behaves_like block
  ###
  
  let(:serialization) { described_class.new(google_place).to_h }

  let(:attributes) { 
    [ 
      :address_components, 
      :formatted_address, 
      :geometry, 
      :id, 
      :name 
    ] 
  }
  
  it "faithfully serializes object as a google place" do
    attributes.each do |attr|
      expect(serialization[attr]).to eq(google_place.send(attr))
    end
  end
  
end
