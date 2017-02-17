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

  it 'should allow storage of serialized numbers, arrays, booleans' do
    bool_config = create(:bool_config)
    expect(Config.bool_config).to eq(!!Config.bool_config)

    array_config = create(:array_config)
    expect(Config.array_config).to be_a(Array)

    num_config = create(:num_config)
    expect(Config.num_config).to be_a(Float)
  end
end
