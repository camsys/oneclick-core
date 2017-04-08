require 'rails_helper'

RSpec.describe Accommodation, type: :model do
  let!(:wheelchair) { FactoryGirl.create :wheelchair }

  it { should have_and_belong_to_many :users }
  it { should have_and_belong_to_many :services }
  it { should respond_to :code }
  it { should respond_to :snake_casify }

  it 'returns an api_hash' do
    expect(wheelchair.api_hash[:code]).to eq(wheelchair.code)
    expect(wheelchair.api_hash[:note]).to eq('missing key accommodation_' + wheelchair.code + '_note')
    expect(wheelchair.api_hash[:name]).to eq('missing key accommodation_' + wheelchair.code + '_name')
    expect(wheelchair.api_hash[:question]).to eq('missing key accommodation_' + wheelchair.code + '_question')
  end

end
