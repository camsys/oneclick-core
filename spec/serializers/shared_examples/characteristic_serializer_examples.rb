# Pass it a characteristic record, and a serialized hash of the characteristic
RSpec.shared_examples "characteristic_serializer" do
  
  # Set characteristic variable in the it_behaves_like block
  
  # Make a serialization for each locale
  let(:serializations) do
    I18n.available_locales.map do |l|
      [l, described_class.new(characteristic, scope: {locale: l}).to_h]
    end.to_h
  end  
  
  it "faithfully serializes a characteristic, by locale" do
    serializations.each do |loc, char_hash|
      expect(char_hash[:code]).to eq(characteristic.code.to_s)
      expect(char_hash[:name]).to eq(characteristic.send("#{loc}_name"))
      expect(char_hash[:note]).to eq(characteristic.send("#{loc}_note"))
      expect(char_hash[:question]).to eq(characteristic.send("#{loc}_question"))
    end
  end
  
end
