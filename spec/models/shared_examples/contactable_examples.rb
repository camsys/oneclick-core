require 'rails_helper'

RSpec.shared_examples "contactable" do |field_mappings|
  let(:phone_field) { field_mappings[:phone] }
  let(:email_field) { field_mappings[:email] }
  let(:url_field) { field_mappings[:url] }
  
  let(:factory) { described_class.to_s.underscore.to_sym }
  
  let(:contactable) { create(factory) }
  
  it "sets up contact fields" do
    expect(described_class).to respond_to(:contact_fields)
  end
  
  it "normalizes phone number field if possible" do
    if(phone_field)
      contactable.send("#{phone_field}=", "1-800-WEIRDPHONENUMBER")
      contactable.save
      expect(contactable.send(phone_field)).to eq("1-800-WEIRDPHONENUMBER")
      expect(contactable.send("formatted_#{phone_field}")).to eq(contactable.phone)
      
      contactable.phone = "555-555-5555"
      contactable.save
      expect(contactable.send(phone_field)).to eq("+15555555555")
      expect(contactable.send("formatted_#{phone_field}")).to eq("(555) 555-5555")
    else
      true
    end
  end

  it "validates email field" do
    if(email_field)
      expect(contactable)
        .to allow_values("goodemail@email.com")
        .for(email_field)
      expect(contactable)
        .not_to allow_values("bademail@notaurl", "not even an email at all", "invalid@@email.com")
        .for(email_field)
    else
      true
    end
  end
  
  it "normalizes and validates url field" do
    if(url_field)
      expect(contactable)
        .to allow_values(nil, 
          "www.missing_scheme.com", 
          "http://anothergood.url.org", 
          "https://www.cool-url.gov/with_an_extension?andparams=cool")
        .for(url_field)
        
      contactable.send("#{url_field}=", "www.missing_scheme.com")
      contactable.save
      expect(contactable.send(url_field)).to eq("http://www.missing_scheme.com")
    else
      true
    end
  end
  
end
