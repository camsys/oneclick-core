require 'rails_helper'

RSpec.describe Config, type: :model do
  it { should respond_to :key }
  it { should respond_to :value }

  let(:config) {create(:config)}

  it 'should respond the value of configs that have been set' do
    expect(Config.send(config.key)).to eq(config.value)
  end

  it 'should repond nil to non-existent config methods' do
    expect(Config.fake_key).to be_nil
  end
end
