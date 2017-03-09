require 'rails_helper'

RSpec.describe Itinerary, type: :model do
  it { should belong_to :trip }
  it { should belong_to :service }
  it { should respond_to :start_time, :end_time, :legs, :walk_time, :transit_time, :cost }

  let(:itinerary) { create(:transit_itinerary) }

  it 'duration returns sum of walk and transit time' do
    expect(itinerary.duration).to eq(itinerary.transit_time + itinerary.walk_time)
  end
end
