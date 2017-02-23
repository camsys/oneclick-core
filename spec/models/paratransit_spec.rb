require 'rails_helper'

RSpec.describe Paratransit, type: :model do

  let(:paratransit) { create(:paratransit)}
  
  it 'paratransit service should be a Paratransit and have appropriate attributes' do
    expect(paratransit).to be
    expect(paratransit).to be_a(Paratransit)
  end

end
