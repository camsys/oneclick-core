require 'rails_helper'

RSpec.describe Itinerary, type: :model do
  it { should belong_to :trip }
  it { should belong_to :service }
  it { should respond_to :start_time, :end_time, :legs, :walk_time, :transit_time, :cost }

  let(:itinerary) { create(:transit_itinerary) }

  it 'duration returns sum of walk and transit time' do
    expect(itinerary.duration).to eq(itinerary.transit_time + itinerary.walk_time)
  end

  it 'selects itself' do
    itinerary.select
    expect(itinerary.selecting_trip).to eq(itinerary.trip)
  end

  it 'selects and unselects itself' do 
    itinerary.select
    expect(itinerary.selecting_trip).to eq(itinerary.trip)

    itinerary.unselect
    itinerary.reload
    itinerary.trip.reload 
    expect(itinerary.trip.selected_itinerary).to eq(nil)
  end

end
