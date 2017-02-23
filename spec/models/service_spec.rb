require 'rails_helper'

RSpec.describe Service, type: :model do
  it { should respond_to :name }
  it { should respond_to :type }

  let(:service) { create(:service)}

  it 'should have a logo with a thumbnail version' do
    expect(service.logo_url).to be
    expect(service.logo.content_type[0..4]).to eq("image")
    expect(service.logo.thumb).to be
  end

end
