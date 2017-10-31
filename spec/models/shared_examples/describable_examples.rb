require 'rails_helper'

RSpec.shared_examples "describable" do
  let(:factory) { described_class.to_s.underscore.to_sym }
  
  let(:describable) { create(factory) }
  
  it { should respond_to :description, :descriptions, 
        :set_description_translation,
        :delete_translations, :description_translation_key }
  
  # Should have a description setter and getter for each locale
  it { should respond_to *I18n.available_locales.flat_map {|l| ["#{l}_description", "#{l}_description="] }}
  
  it "sets and retrieves translations by locale" do
    
    # Set all the translations by locale
    I18n.available_locales.each do |l| 
      describable.set_description_translation(l, "#{l} translation")
    end
    
    # Retrieve all the translations by locale
    I18n.available_locales.each do |l|
      expect(describable.description(l)).to eq("#{l} translation")
    end
    
    # Reset the translations using the custom setters
    I18n.available_locales.each do |l|
      describable.send("#{l}_description=", "#{l} translation 2")
    end
    
    # Retrieve the translations using the custom getters
    I18n.available_locales.each do |l|
      expect(describable.send("#{l}_description")).to eq("#{l} translation 2")
    end
    
  end
  
  it "destroys translations after object is destroyed" do
    I18n.available_locales.each {|l| describable.set_description_translation(l, "#{l} translation")}
    t_key = describable.description_translation_key
    expect(TranslationKey.find_by(name: t_key)).to be
    describable.destroy
    expect(TranslationKey.find_by(name: t_key)).not_to be
  end
  
end
