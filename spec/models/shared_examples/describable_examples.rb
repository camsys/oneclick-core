require 'rails_helper'

RSpec.shared_examples "describable" do
  let(:factory) { described_class.to_s.underscore.to_sym }
  
  let(:describable) { create(factory) }
  
  it { should respond_to :description, :descriptions, 
        :set_description_translation, :en_description, :en_description=,
        :delete_translations, :description_translation_key }
  
  pending "EXAMPLES FOR DESCRIBABLE"
  
end
