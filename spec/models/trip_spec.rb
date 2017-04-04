require 'rails_helper'

RSpec.describe Trip, type: :model do
  it { should belong_to :user }
  it { should have_many(:itineraries).dependent(:destroy) }
  it { should belong_to(:origin).class_name('Waypoint').dependent(:destroy) }
  it { should belong_to(:destination).class_name('Waypoint').dependent(:destroy) }

  let(:itinerary) { create(:transit_itinerary) }

  it 'unselects itself' do
    trip = itinerary.trip
    itinerary.select
    expect(trip.selected_itinerary).to eq(itinerary)

    trip.unselect
    trip.reload
    expect(trip.selected_itinerary).to eq(nil)
  end

end
