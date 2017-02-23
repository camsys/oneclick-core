require 'rails_helper'

RSpec.describe Transit, type: :model do

  let(:transit) { create(:transit)}

  it 'transit service should be a Transit and have appropriate attributes' do
    expect(transit).to be
    expect(transit).to be_a(Transit)
    expect(transit.gtfs_agency_id).to be
  end

end
